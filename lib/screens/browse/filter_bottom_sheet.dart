import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/filter/filter_bloc.dart';
import '../../../bloc/filter/filter_event.dart';
import '../../../bloc/filter/filter_state.dart';
import '../../../bloc/browse/browse_bloc.dart';
import '../../../bloc/browse/browse_event.dart';
import '../../../models/filter_criteria.dart';
import '../../../config/theme.dart';
import 'package:intl/intl.dart';
import '../../widgets/location_picker.dart';
import '../../services/geocoding_service.dart';

/// Filter bottom sheet with price, distance, date, and status filters
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context, {FilterBloc? filterBloc, BrowseBloc? browseBloc}) {
    final effectiveFilterBloc = filterBloc ?? context.read<FilterBloc>();
    final effectiveBrowseBloc = browseBloc ?? context.read<BrowseBloc>();
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (newContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: effectiveFilterBloc),
          BlocProvider.value(value: effectiveBrowseBloc),
        ],
        child: const FilterBottomSheet(),
      ),
    );
  }


  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  double _distance = 25;
  double? _latitude;
  double? _longitude;
  String? _locationName;
  DateTime? _fromDate;
  DateTime? _toDate;
  List<String> _selectedStatus = ['open'];

  @override
  void initState() {
    super.initState();
    final filterState = context.read<FilterBloc>().state;
    final criteria = filterState is FilterApplied ? filterState.criteria : const FilterCriteria();
    
    _minPriceController = TextEditingController(text: criteria.minPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController = TextEditingController(text: criteria.maxPrice?.toStringAsFixed(0) ?? '');
    _distance = criteria.distanceKm ?? 25;
    _latitude = criteria.latitude;
    _longitude = criteria.longitude;
    _locationName = criteria.locationName;
    _fromDate = criteria.fromDate;
    _toDate = criteria.toDate;
    _selectedStatus = List.from(criteria.taskStatus);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize:0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.divider)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<FilterBloc>().add(ClearFilters());
                      setState(() {
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        _distance = 25;
                        _latitude = null;
                        _longitude = null;
                        _locationName = null;
                        _fromDate = null;
                        _toDate = null;
                        _selectedStatus = ['open'];
                      });
                    },
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Price Range
                  const Text(
                    'Price Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Min (USD)',
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Max (USD)',
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Location
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildLocationSelector(),
                  
                  const SizedBox(height: 32),
                  
                  // Distance
                  const Text(
                    'Distance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Within ${_distance.toInt()} km',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  Slider(
                    value: _distance,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_distance.toInt()} km',
                    onChanged: (value) => setState(() => _distance = value),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date Range
                  const Text(
                    'Date Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _fromDate = date);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_fromDate != null ? DateFormat('MMM d, y').format(_fromDate!) : 'From'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _toDate ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: _fromDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _toDate = date);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_toDate != null ? DateFormat('MMM d, y').format(_toDate!) : 'To'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Task Status
                  const Text(
                    'Task Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0E1638)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _buildStatusChips(),
                  ),
                ],
              ),
            ),
            
            // Apply button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.divider)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildStatusChips() {
    final statuses = [
      {'value': 'open', 'label': 'Open'},
      {'value': 'assigned', 'label': 'Assigned'},
      {'value': 'completed', 'label': 'Completed'},
    ];
    
    return statuses.map((status) {
      final value = status['value']!;
      final label = status['label']!;
      final isSelected = _selectedStatus.contains(value);
      
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedStatus.add(value);
            } else {
              if (_selectedStatus.length > 1) {
                _selectedStatus.remove(value);
              }
            }
          });
        },
        selectedColor: AppTheme.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.neutral700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: AppTheme.neutral50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.neutral200),
        ),
        showCheckmark: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    }).toList();
  }

  Widget _buildLocationSelector() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    AppBar(
                      title: const Text('Select Location'),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: LocationPicker(
                        initialAddress: _locationName,
                        initialLat: _latitude,
                        initialLng: _longitude,
                        onLocationSelected: (result) {
                          setState(() {
                            _locationName = result.address;
                            _latitude = result.latitude;
                            _longitude = result.longitude;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.navy, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationName ?? 'Select search area',
                        style: TextStyle(
                          fontWeight: _locationName != null ? FontWeight.w600 : FontWeight.normal,
                          color: _locationName != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_latitude != null && _longitude != null)
                        Text(
                          '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _useCurrentLocation,
          icon: const Icon(Icons.my_location, size: 16),
          label: const Text('Use my current location'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.navy,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Future<void> _useCurrentLocation() async {
    final geocoding = GeocodingService();
    final position = await geocoding.getCurrentLocation();
    
    if (position != null) {
      final result = await geocoding.reverseGeocode(position.latitude, position.longitude);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName = result?.displayName ?? 'Current Location';
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  void _applyFilters() {
    final criteria = FilterCriteria(
      minPrice: _minPriceController.text.isNotEmpty ? double.tryParse(_minPriceController.text) : null,
      maxPrice: _maxPriceController.text.isNotEmpty ? double.tryParse(_maxPriceController.text) : null,
      distanceKm: _distance > 0 ? _distance : null,
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
      fromDate: _fromDate,
      toDate: _toDate,
      taskStatus: _selectedStatus,
    );
    
    context.read<FilterBloc>().add(UpdateFilter(criteria));
    context.read<FilterBloc>().add(ApplyFilters());
    context.read<BrowseBloc>().add(LoadBrowseTasks(criteria: criteria));
    
    Navigator.pop(context);
  }
}
