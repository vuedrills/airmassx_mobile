import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../models/sort_option.dart';
import '../../models/filter_criteria.dart';
import '../../models/ad.dart';
import 'browse_event.dart';
import 'browse_state.dart';

/// Browse BLoC - Handles task browsing with filtering, sorting, and view toggling
class BrowseBloc extends Bloc<BrowseEvent, BrowseState> {
  final ApiService _apiService;

  BrowseBloc(this._apiService) : super(BrowseInitial()) {
    on<LoadBrowseTasks>(_onLoadBrowseTasks);
    on<LoadBrowseTasksWithFilter>(_onLoadBrowseTasksWithFilter);
    on<SelectCategory>(_onSelectCategory);
    on<SetSortOption>(_onSetSortOption);
    on<ToggleView>(_onToggleView);
    on<LoadMoreTasks>(_onLoadMoreTasks);
  }

  Future<void> _onLoadMoreTasks(
    LoadMoreTasks event,
    Emitter<BrowseState> emit,
  ) async {
    if (state is! BrowseLoaded) return;
    final currentState = state as BrowseLoaded;

    if (currentState.hasReachedMax || currentState.isFetchingMore) return;

    // Set loading state to prevent duplicate requests
    emit(currentState.copyWith(isFetchingMore: true));

    try {
      final limit = 20;
      // Use totalFetched (raw server cursor) instead of filtered tasks.length
      final offset = currentState.totalFetched;

      final newTasks = await _apiService.getTasks(
        taskType: currentState.taskType,
        tier: currentState.tier,
        limit: limit,
        offset: offset,
      );

      // Track rawCount before filtering
      final rawCount = newTasks.length;

      // Filter new tasks
      final visibleNewTasks = _filterVisibleTasks(newTasks);

      // Deduplicate: remove any tasks that already exist in the current list
      final existingIds = currentState.tasks.map((t) => t.id).toSet();
      final uniqueNewTasks = visibleNewTasks.where((t) => !existingIds.contains(t.id)).toList();

      final newTotalFetched = offset + rawCount;

      if (uniqueNewTasks.isEmpty && rawCount > 0) {
        // All new tasks were duplicates or filtered out, but server had data
        emit(currentState.copyWith(
          hasReachedMax: rawCount < limit,
          isFetchingMore: false,
          totalFetched: newTotalFetched,
        ));
      } else if (rawCount == 0) {
        emit(currentState.copyWith(
          hasReachedMax: true,
          isFetchingMore: false,
          totalFetched: newTotalFetched,
        ));
      } else {
        emit(currentState.copyWith(
          tasks: List.of(currentState.tasks)..addAll(uniqueNewTasks),
          hasReachedMax: rawCount < limit,
          page: currentState.page + 1,
          isFetchingMore: false,
          totalFetched: newTotalFetched,
        ));
      }
    } catch (e) {
      print('Pagination error: $e');
      // Reset loading state on error so user can try again
      emit(currentState.copyWith(isFetchingMore: false));
    }
  }

  Future<void> _onLoadBrowseTasks(
    LoadBrowseTasks event,
    Emitter<BrowseState> emit,
  ) async {
    final currentTasks = state is BrowseLoaded ? (state as BrowseLoaded).tasks : <Task>[];
    final currentCategories = state is BrowseLoaded ? (state as BrowseLoaded).categories : <Category>[];
    final currentSort = state is BrowseLoaded ? (state as BrowseLoaded).sortOption : SortOption.newestPosted;
    final isMapView = state is BrowseLoaded ? (state as BrowseLoaded).isMapView : false;
    final currentTaskType = state is BrowseLoaded ? (state as BrowseLoaded).taskType : null;
    final currentTier = state is BrowseLoaded ? (state as BrowseLoaded).tier : null;

    emit(BrowseLoading());
    try {
      
      // Fetch tasks and ads in parallel
      final results = await Future.wait([
        _apiService.getTasks(
          criteria: event.criteria,
          taskType: currentTaskType,
          tier: currentTier,
        ),
        _apiService.getAds(),
        currentCategories.isEmpty ? _apiService.getCategories() : Future.value(currentCategories),
        _apiService.getAdsFrequency(),
      ]);

      final rawTasks = results[0] as List<Task>;
      final tasks = _filterVisibleTasks(rawTasks);
      final ads = results[1] as List<Ad>;
      final categories = results[2] as List<Category>;
      final adsFrequency = results[3] as int;
      
      emit(BrowseLoaded(
        tasks: tasks,
        categories: categories,
        ads: ads,
        sortOption: currentSort,
        isMapView: isMapView,
        taskType: currentTaskType,
        tier: currentTier,
        adsFrequency: adsFrequency,
        totalFetched: rawTasks.length,
      ));
    } catch (e) {
      emit(BrowseError(ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  int _currentRequestId = 0;

  Future<void> _onLoadBrowseTasksWithFilter(
    LoadBrowseTasksWithFilter event,
    Emitter<BrowseState> emit,
  ) async {
    final requestId = ++_currentRequestId;
    emit(BrowseLoading());
    try {
      // Map legacy event to FilterCriteria
      final criteria = const FilterCriteria();
      
      // Fetch tasks, categories, and ads in parallel
      final results = await Future.wait([
        _apiService.getTasks(
          criteria: criteria,
          taskType: event.taskType,
          tier: event.tier,
        ),
        _apiService.getCategories(),
        _apiService.getAds(),
        _apiService.getAdsFrequency(),
      ]);
      
      // Check if this request is still the latest one
      if (requestId != _currentRequestId) {
        return; // Ignore stale result
      }
      
      final rawTasks = results[0] as List<Task>;
      final tasks = _filterVisibleTasks(rawTasks);
      final categories = results[1] as List<Category>;
      final ads = results[2] as List<Ad>;
      final adsFrequency = results[3] as int;

      emit(BrowseLoaded(
        tasks: tasks,
        categories: categories,
        ads: ads,
        taskType: event.taskType,
        tier: event.tier,
        adsFrequency: adsFrequency,
        totalFetched: rawTasks.length,
      ));
    } catch (e) {
      if (requestId == _currentRequestId) {
         emit(BrowseError(ErrorHandler.getUserFriendlyMessage(e)));
      }
    }
  }

  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<BrowseState> emit,
  ) async {
    // Determine the base state to work from (must have categories)
    if (state is! BrowseLoaded) return; 
    
    final currentState = state as BrowseLoaded;
    final categoryId = event.categoryId ?? 'all';
    final taskType = currentState.taskType;
    final tier = currentState.tier;
    
    // Update the UI immediately to show the selected chip
    emit(currentState.copyWith(
      selectedCategoryId: categoryId,
    ));
    
    try {
      if (categoryId == 'all') {
        final tasks = await _apiService.getTasks(taskType: taskType, tier: tier);
        // Since we emit immediately above, we might be in a new state now
        if (state is BrowseLoaded) {
          emit((state as BrowseLoaded).copyWith(tasks: tasks));
        }
      } else {
        // Find the category from the ID
        final selectedCategory = currentState.categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => currentState.categories.first,
        );
        
        // Filter tasks by category name (mocking server-side filtering)
        final allTasks = await _apiService.getTasks(taskType: taskType, tier: tier);
        
        // Get all child category names if this is a parent
        final childCategories = currentState.categories
            .where((c) => c.parentId == selectedCategory.id)
            .map((c) => c.name.toLowerCase())
            .toList();
            
        final filteredTasks = allTasks.where((task) {
          final taskCat = task.category.toLowerCase();
          final matchesSelf = taskCat == selectedCategory.name.toLowerCase();
          final matchesChild = childCategories.contains(taskCat);
          return matchesSelf || matchesChild;
        }).toList();
        
        final visibleFilteredTasks = _filterVisibleTasks(filteredTasks);
        
        if (state is BrowseLoaded) {
          emit((state as BrowseLoaded).copyWith(tasks: visibleFilteredTasks));
        }
      }
    } catch (e) {
      emit(BrowseError(ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Future<void> _onSetSortOption(
    SetSortOption event,
    Emitter<BrowseState> emit,
  ) async {
    if (state is BrowseLoaded) {
      final currentState = state as BrowseLoaded;
      final sortedTasks = _sortTasks(currentState.tasks, event.sortOption);
      
      emit(currentState.copyWith(
        tasks: sortedTasks,
        sortOption: event.sortOption,
      ));
    }
  }

  Future<void> _onToggleView(
    ToggleView event,
    Emitter<BrowseState> emit,
  ) async {
    if (state is BrowseLoaded) {
      final currentState = state as BrowseLoaded;
      emit(currentState.copyWith(isMapView: event.isMapView));
    }
  }

  List<Task> _sortTasks(List<Task> tasks, SortOption sortOption) {
    final sortedTasks = List<Task>.from(tasks);
    
    switch (sortOption) {
      case SortOption.newestPosted:
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.mostRelevant:
        // Default sorting (already sorted by relevance)
        break;
      case SortOption.highestBudget:
        sortedTasks.sort((a, b) => b.budget.compareTo(a.budget));
        break;
      case SortOption.lowestBudget:
        sortedTasks.sort((a, b) => a.budget.compareTo(b.budget));
        break;
      case SortOption.endingSoon:
        sortedTasks.sort((a, b) {
          // Handle null deadlines by putting them at the end
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
        break;
    }
    
    
    return sortedTasks;
  }

  List<Task> _filterVisibleTasks(List<Task> tasks) {
    return tasks.where((t) {
      // 1. Hide cancelled tasks
      if (t.status == 'cancelled') return false;
      
      // 2. Hide completed tasks older than 14 days
      if (t.status == 'completed') {
        final date = t.updatedAt ?? t.createdAt;
        final difference = DateTime.now().difference(date);
        if (difference.inDays > 14) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
