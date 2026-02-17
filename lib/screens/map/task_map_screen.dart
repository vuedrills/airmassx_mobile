import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/geocoding_service.dart';
import '../../core/service_locator.dart';
import '../tasks/task_detail_screen.dart';
import '../browse/search_modal.dart';
import '../../bloc/search/search_bloc.dart';
import '../../bloc/browse/browse_bloc.dart';
import '../../widgets/dynamic_map.dart';
import '../../bloc/map_settings/map_settings_cubit.dart';

/// Task Map View - Shows tasks on an OpenStreetMap
class TaskMapScreen extends StatefulWidget {
  final List<Task>? initialTasks;
  final String? taskType; // 'service' or 'equipment'
  final Task? initialTask; // Task to initially focus on

  const TaskMapScreen({
    super.key,
    this.initialTasks,
    this.taskType,
    this.initialTask,
  });

  @override
  State<TaskMapScreen> createState() => _TaskMapScreenState();
}

class _TaskMapScreenState extends State<TaskMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  List<Category> _categories = [];
  Map<String, LatLng> _geocodedLocations = {}; // Cache for geocoded locations
  bool _isLoading = true;
  Task? _selectedTask;
  String? _selectedCategory;

  // Default center (Harare, Zimbabwe)
  static const LatLng _defaultCenter = LatLng(-17.8252, 31.0335);

  // CARTO Positron - Light greyish-blue map style (matches web app)
  static const String _mapTileUrl = 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (widget.initialTask != null) {
      _selectedTask = widget.initialTask!;
      // Add initial task to list if not present
      if (_tasks.isEmpty) { 
        _tasks = [widget.initialTask!];
        _filteredTasks = _tasks;
      }
      
      // Delay map move until layout is done
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loc = _getTaskLocation(widget.initialTask!);
        if (loc != null) {
           _animatedMapMove(loc, 15.0);
        }
      });
    }

    if (widget.initialTasks != null && widget.initialTasks!.isNotEmpty) {
      _tasks = widget.initialTasks!;
      _filteredTasks = _tasks;
      _isLoading = false;
      _geocodeTasksWithoutCoordinates();
    } else {
      // Always load all tasks if not explicitly provided list (except single init task)
      _loadTasks();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final apiService = getIt<ApiService>();
      final categories = await apiService.getCategories();
      print('TaskMapScreen: Loaded ${categories.length} categories');
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final apiService = getIt<ApiService>();
      // Fetch more tasks for the map view to ensure we see everything
      final tasks = await apiService.getTasks(
        taskType: widget.taskType,
        limit: 100, 
      );
      
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _filteredTasks = _applyFilter(tasks);
        _isLoading = false;
      });
      // Geocode tasks that don't have coordinates
      _geocodeTasksWithoutCoordinates();
    } catch (e) {
      print('Error loading tasks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  AnimationController? _mapAnimationController;

  @override
  void dispose() {
    _mapAnimationController?.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Clean up any existing animation
    _mapAnimationController?.dispose();
    _mapAnimationController = null;

    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _mapAnimationController = controller;
    
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
        if (_mapAnimationController == controller) {
          _mapAnimationController = null;
        }
      }
    });

    controller.forward();
  }

  Future<void> _geocodeTasksWithoutCoordinates() async {
    for (final task in _tasks) {
      if (task.locationLat == null || task.locationLng == null) {
        // Check cache first
        if (!_geocodedLocations.containsKey(task.id)) {
          if (!mounted) return;
          try {
            final results = await _geocodingService.searchPlaces(task.locationAddress);
            if (results.isNotEmpty && mounted) {
              setState(() {
                _geocodedLocations[task.id] = LatLng(results.first.lat, results.first.lng);
              });
            }
          } catch (e) {
            print('Failed to geocode task ${task.id}: $e');
          }
          // Small delay to avoid rate limiting
          if (!mounted) return;
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }
  }

  LatLng? _getTaskLocation(Task task) {
    // First check if task has coordinates
    if (task.locationLat != null && task.locationLng != null) {
      return LatLng(task.locationLat!, task.locationLng!);
    }
    // Then check geocoded cache
    return _geocodedLocations[task.id];
  }

  List<DynamicMarker> _buildDynamicMarkers() {
    return _filteredTasks
        .map((task) {
          final location = _getTaskLocation(task);
          if (location == null) return null;
          
          final isEquipment = task.taskType.toLowerCase() == 'equipment' || 
                              task.category.toLowerCase().contains('equipment') ||
                              task.category.toLowerCase().contains('plant') ||
                              task.category.toLowerCase().contains('machinery') ||
                              task.costingBasis != null || 
                              task.hireDurationType != null ||
                              task.equipmentUnits != null ||
                              // Common equipment categories
                              ['excavator', 'loader', 'generator', 'tipper', 'tlb', 'roller'].contains(task.category.toLowerCase());
                              
          final markerColor = isEquipment ? Colors.green : AppTheme.accentRed;
          final googleHue = isEquipment ? 120.0 : 0.0;
          
          return DynamicMarker(
            id: task.id,
            point: location,
            googleHue: googleHue,
            width: 22,
            height: 22,
            onTap: () {
                setState(() {
                  _selectedTask = task;
                });
            },
            child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
            ),
          );
        })
        .whereType<DynamicMarker>()
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.taskType == 'equipment'
            ? 'Equipment Map'
            : 'Tasks Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.neutral500),
            onPressed: () {
              SearchModal.show(
                context,
                searchBloc: getIt<SearchBloc>(),
                browseBloc: getIt<BrowseBloc>(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neutral500),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            DynamicMap(
              osmController: _mapController,
              initialCenter: _defaultCenter,
              initialZoom: 12,
              forceProvider: MapProvider.osm,
              tileUrl: _mapTileUrl,
              showCircle: _selectedTask != null,
              circleRadius: 400, // Show 400m radius
              onTap: (latLng) {
                  setState(() {
                    _selectedTask = null;
                  });
              },
              markers: _buildDynamicMarkers(),
            ),
  
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
  
            // Zoom controls (mimicking web app style)
            Positioned(
              top: 80, // Offset from top to avoid overlapping with top-left badge
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMapActionBtn(Icons.add, () {
                      final zoom = _mapController.camera.zoom + 1;
                      _mapController.move(_mapController.camera.center, zoom);
                    }),
                    Container(height: 1, width: 24, color: Colors.grey.shade200),
                    _buildMapActionBtn(Icons.remove, () {
                      final zoom = _mapController.camera.zoom - 1;
                      _mapController.move(_mapController.camera.center, zoom);
                    }),
                    Container(height: 1, width: 24, color: Colors.grey.shade200),
                    _buildMapActionBtn(Icons.my_location, () {
                      _mapController.move(_defaultCenter, 12);
                    }),
                  ],
                ),
              ),
            ),
  
            // Task count & Legend
            Positioned(
              top: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_buildDynamicMarkers().length} items on map',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(AppTheme.accentRed, 'Tasks'),
                        const SizedBox(height: 4),
                        _buildLegendItem(Colors.green, 'Equipment'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
  
            // Selected task card
            if (_selectedTask != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildSelectedTaskCard(),
              ),
  
            // Category Dropdown Filter
            Positioned(
              top: 16,
              right: 16,
              left: 150, // Avoid overlapping with "items on map" badge
              child: _buildCategoryDropdown(),
            ),
          ],
        ),
      ),
    );
  }

  List<Task> _applyFilter(List<Task> tasks) {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return tasks;
    }
    return tasks.where((t) => t.category == _selectedCategory).toList();
  }

  void _onCategoryChanged(String? newValue) {
    setState(() {
      _selectedCategory = newValue;
      _filteredTasks = _applyFilter(_tasks);
      _selectedTask = null; // Clear selection when filter changes
    });
  }

  Widget _buildCategoryDropdown() {
    // Group categories
    final tradesRaw = _categories.where((c) => c.tier == 'artisanal' || c.tier == 'automotive').toList();
    final professionalsRaw = _categories.where((c) => c.tier == 'professional').toList();
    final equipmentRaw = _categories.where((c) => c.tier == 'equipment').toList();

    // Helper to move 'Other' to end
    List<Category> _moveOtherToEnd(List<Category> list) {
      final normal = list.where((c) => c.name.toLowerCase() != 'other').toList();
      final other = list.where((c) => c.name.toLowerCase() == 'other').toList();
      return [...normal, ...other];
    }

    final trades = _moveOtherToEnd(tradesRaw);
    final professionals = _moveOtherToEnd(professionalsRaw);
    final equipment = _moveOtherToEnd(equipmentRaw);

    final Set<String> seenNames = {};

    List<DropdownMenuItem<String>> buildItems(List<Category> categories) {
      final List<DropdownMenuItem<String>> items = [];
      for (final c in categories) {
        if (!seenNames.contains(c.name)) {
          seenNames.add(c.name);
          items.add(DropdownMenuItem(
            value: c.name,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(c.name),
            ),
          ));
        }
      }
      return items;
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory ?? 'All',
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          isExpanded: true,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          onChanged: _onCategoryChanged,
          items: [
            const DropdownMenuItem(
              value: 'All',
              child: Text('All Categories'),
            ),
            
            if (trades.isNotEmpty) ...[
              const DropdownMenuItem(
                enabled: false,
                child: Text(
                  'TRADES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...buildItems(trades),
            ],

            if (professionals.isNotEmpty) ...[
              const DropdownMenuItem(
                enabled: false,
                child: Text(
                  'PROFESSIONAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...buildItems(professionals),
            ],

            if (equipment.isNotEmpty) ...[
              const DropdownMenuItem(
                enabled: false,
                child: Text(
                  'EQUIPMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...buildItems(equipment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTaskCard() {
    final task = _selectedTask!;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: task.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Task image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.navy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: task.photos.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          task.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.task_alt,
                            color: AppTheme.navy,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.task_alt,
                        color: AppTheme.navy,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.locationAddress,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Budget
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${task.budget.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.navy,
                    ),
                  ),
                  const Text(
                    'budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20, color: AppTheme.navy),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
