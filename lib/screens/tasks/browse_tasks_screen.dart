import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/browse/browse_bloc.dart';
import '../../bloc/browse/browse_event.dart';
import '../../bloc/browse/browse_state.dart';
import '../../bloc/search/search_bloc.dart';
import '../../bloc/filter/filter_bloc.dart';
import '../../bloc/filter/filter_event.dart';
import '../../bloc/filter/filter_state.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/enhanced_task_card.dart';
import '../../widgets/filter_chip.dart' as custom;
import '../../widgets/active_filters_list.dart';
import '../browse/search_modal.dart';
import '../browse/filter_bottom_sheet.dart';
import '../browse/sort_bottom_sheet.dart';
import '../browse/category_grid_view.dart';
import '../map/task_map_screen.dart';
import '../../models/filter_criteria.dart';

/// Enhanced browse tasks screen with search, filters, categories, and sort
class BrowseTasksScreen extends StatefulWidget {
  const BrowseTasksScreen({super.key});

  @override
  State<BrowseTasksScreen> createState() => _BrowseTasksScreenState();
}

class _BrowseTasksScreenState extends State<BrowseTasksScreen> {
  late BrowseBloc _browseBloc;
  late SearchBloc _searchBloc;
  late FilterBloc _filterBloc;

  @override
  void initState() {
    super.initState();
    _browseBloc = getIt<BrowseBloc>();
    _searchBloc = getIt<SearchBloc>();
    _filterBloc = getIt<FilterBloc>();
    // Filter for service tasks only to avoid showing equipment requests here
    _browseBloc.add(LoadBrowseTasksWithFilter(taskType: 'service'));
  }

  @override
  void dispose() {
    _browseBloc.close();
    _searchBloc.close();
    _filterBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _browseBloc),
        BlocProvider.value(value: _searchBloc),
        BlocProvider.value(value: _filterBloc),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Browse Tasks'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
              ],
            ),
            body: Column(
              children: [
                // Search bar
                _buildSearchBar(context),
                
                // Category chips
                const CategoryChips(),
                
                const SizedBox(height: 12),
                
                // Filter/Sort buttons
                _buildFilterSortBar(context),
                
                // Active filter chips
                _buildFilterChips(),
                
                // Task list
                Expanded(
                  child: BlocBuilder<BrowseBloc, BrowseState>(
                    builder: (context, state) {
                      if (state is BrowseLoading) {
                        return _buildLoadingState();
                      }
                      
                      if (state is BrowseLoaded) {
                        // Show all tasks without status filtering
                        var filteredTasks = state.tasks;

                        if (filteredTasks.isEmpty) {
                          return _buildEmptyState();
                        }
                        
                        return RefreshIndicator(
                          onRefresh: () async {
                            final criteria = _filterBloc.state is FilterApplied 
                                ? (_filterBloc.state as FilterApplied).criteria 
                                : const FilterCriteria();
                            _browseBloc.add(LoadBrowseTasks(criteria: criteria));
                            await Future.delayed(const Duration(milliseconds: 500));
                          },
                          child: ListView.builder(
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              return EnhancedTaskCard(task: filteredTasks[index]);
                            },
                          ),
                        );
                      }
                      
                      if (state is BrowseError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(state.message),
                            ],
                          ),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => SearchModal.show(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Search for any task',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSortBar(BuildContext context) {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, filterState) {
        final filterCount = filterState is FilterApplied 
            ? filterState.criteria.activeFilterCount 
            : 0;
            
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Map View button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TaskMapScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on_outlined, size: 20),
                label: const Text('Map'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: AppTheme.navy,
                ),
              ),
              
              const SizedBox(width: 12),

              // Filter button
              OutlinedButton.icon(
                onPressed: () => FilterBottomSheet.show(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.filter_list, size: 20),
                    if (filterCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.navy,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$filterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: const Text('Filters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: AppTheme.navy,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Sort button
              OutlinedButton.icon(
                onPressed: () => SortBottomSheet.show(context),
                icon: const Icon(Icons.sort, size: 20),
                label: const Text('Sort'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              
              const Spacer(),
              
              // View categories button
              TextButton(
                onPressed: () {
                  final state = _browseBloc.state;
                  if (state is BrowseLoaded) {
                    CategoryGridView.show(context, state.categories);
                  }
                },
                child: const Text('See all categories'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, state) {
        if (state is! FilterApplied) {
          return const SizedBox.shrink();
        }
        
        return ActiveFiltersList(
          criteria: state.criteria,
          onUpdate: (newCriteria) {
            _filterBloc.add(UpdateFilter(newCriteria));
            _filterBloc.add(ApplyFilters());
            _browseBloc.add(LoadBrowseTasks(criteria: newCriteria));
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 64, color: AppTheme.neutral300),
            ),
            const SizedBox(height: 24),
            Text(
              'No tasks found',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any tasks matching your current filters. Try adjusting your search area or price range.',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutral500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/create-task');
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Post a Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _filterBloc.add(const UpdateFilter(FilterCriteria()));
                _filterBloc.add(ApplyFilters());
                _browseBloc.add(const LoadBrowseTasks(criteria: FilterCriteria()));
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Clear All Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.navy,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 80, height: 12, color: Colors.white),
                    const Spacer(),
                    Container(width: 40, height: 12, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 12),
                Container(width: 200, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 14, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 150, height: 14, color: Colors.white),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 12, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(width: 40, height: 10, color: Colors.white),
                      ],
                    ),
                    const Spacer(),
                    Container(width: 70, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
