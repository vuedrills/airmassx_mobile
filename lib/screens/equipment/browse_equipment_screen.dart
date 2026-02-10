import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/browse/browse_bloc.dart';
import '../../bloc/browse/browse_event.dart';
import '../../bloc/browse/browse_state.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';
import '../../widgets/task/task_card.dart';
import '../tasks/task_detail_screen.dart';
import '../map/task_map_screen.dart';
import '../browse/search_modal.dart';
import 'post_equipment_request_screen.dart';

/// Browse Equipment screen - Using same design language as posting forms
class BrowseEquipmentScreen extends StatefulWidget {
  const BrowseEquipmentScreen({super.key});

  @override
  State<BrowseEquipmentScreen> createState() => _BrowseEquipmentScreenState();
}

class _BrowseEquipmentScreenState extends State<BrowseEquipmentScreen> {
  late BrowseBloc _browseBloc;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Category> _equipmentCategories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _browseBloc = getIt<BrowseBloc>();
    _browseBloc.add(LoadBrowseTasksWithFilter(taskType: 'equipment'));
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService().getEquipmentCategories();
      setState(() {
        _equipmentCategories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _browseBloc.close();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
    });
    if (category == 'All') {
      _browseBloc.add(LoadBrowseTasksWithFilter(taskType: 'equipment'));
    } else {
      _browseBloc.add(LoadBrowseTasksWithFilter(
        taskType: 'equipment',
        category: category,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _browseBloc,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Equipment Hire',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.navy,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.map_outlined, color: AppTheme.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskMapScreen(taskType: 'equipment'),
                  ),
                );
              },
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.search, color: AppTheme.primary),
                onPressed: () => SearchModal.show(context, browseBloc: _browseBloc),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Category chips section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: _buildCategoryChips(),
            ),
            
            // Divider
            Container(height: 1, color: Colors.grey.shade200),
            
            // Equipment list
            Expanded(
              child: BlocBuilder<BrowseBloc, BrowseState>(
                builder: (context, state) {
                  if (state is BrowseLoading) {
                    return _buildLoadingState();
                  }
                  
                  if (state is BrowseLoaded) {
                    final tasks = state.tasks;
                    
                    if (tasks.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    return RefreshIndicator(
                      onRefresh: () async {
                        _browseBloc.add(LoadBrowseTasksWithFilter(taskType: 'equipment'));
                      },
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return TaskCard(task: tasks[index]);
                        },
                      ),
                    );
                  }
                  
                  if (state is BrowseError) {
                    return _buildErrorState();
                  }
                  
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_loadingCategories) {
      return SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 100,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Prepend "All" option
    final allCategories = [
      Category(
        id: 'all',
        slug: 'all',
        name: 'All',
        iconName: 'apps-outline',
        type: 'equipment',
        tier: 'equipment',
        verificationLevel: 'basic',
      ),
      ..._equipmentCategories,
    ];

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = category.name == _selectedCategory;
          
          return Padding(
            padding: EdgeInsets.only(right: index < allCategories.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category.name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 150, height: 16, color: Colors.white),
                    Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(width: 8),
                    Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 12, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 200, height: 12, color: Colors.white),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 12, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(width: 60, height: 10, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.construction_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No equipment requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to post a request',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToPostRequest,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Post Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _browseBloc.add(LoadBrowseTasksWithFilter(taskType: 'equipment'));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: 'browse_equipment_post_fab',
      onPressed: _navigateToPostRequest,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  void _navigateToPostRequest() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PostEquipmentRequestScreen(),
      ),
    );
    if (result == true) {
      _browseBloc.add(LoadBrowseTasksWithFilter(taskType: 'equipment'));
    }
  }
}
