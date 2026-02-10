import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  Future<void> _onLoadBrowseTasks(
    LoadBrowseTasks event,
    Emitter<BrowseState> emit,
  ) async {
    final currentTasks = state is BrowseLoaded ? (state as BrowseLoaded).tasks : <Task>[];
    final currentCategories = state is BrowseLoaded ? (state as BrowseLoaded).categories : <Category>[];
    final currentSort = state is BrowseLoaded ? (state as BrowseLoaded).sortOption : SortOption.newestPosted;
    final isMapView = state is BrowseLoaded ? (state as BrowseLoaded).isMapView : false;

    emit(BrowseLoading());
    try {
      
      // Fetch tasks and ads in parallel
      final results = await Future.wait([
        _apiService.getTasks(criteria: event.criteria),
        _apiService.getAds(),
        currentCategories.isEmpty ? _apiService.getCategories() : Future.value(currentCategories),
      ]);

      final tasks = results[0] as List<Task>;
      final ads = results[1] as List<Ad>;
      final categories = results[2] as List<Category>;
      
      emit(BrowseLoaded(
        tasks: tasks,
        categories: categories,
        ads: ads,
        sortOption: currentSort,
        isMapView: isMapView,
      ));
    } catch (e) {
      emit(BrowseError(e.toString()));
    }
  }

  Future<void> _onLoadBrowseTasksWithFilter(
    LoadBrowseTasksWithFilter event,
    Emitter<BrowseState> emit,
  ) async {
    emit(BrowseLoading());
    try {
      // Map legacy event to FilterCriteria
      final criteria = FilterCriteria(
        taskStatus: const ['open'],
      );
      
      // Fetch tasks, categories, and ads in parallel
      final results = await Future.wait([
        _apiService.getTasks(
          criteria: criteria,
          taskType: event.taskType,
          tier: event.tier,
        ),
        _apiService.getCategories(),
        _apiService.getAds(),
      ]);
      
      final tasks = results[0] as List<Task>;
      final categories = results[1] as List<Category>;
      final ads = results[2] as List<Ad>;

      emit(BrowseLoaded(
        tasks: tasks,
        categories: categories,
        ads: ads,
        taskType: event.taskType,
        tier: event.tier,
      ));
    } catch (e) {
      emit(BrowseError(e.toString()));
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
        
        if (state is BrowseLoaded) {
          emit((state as BrowseLoaded).copyWith(tasks: filteredTasks));
        }
      }
    } catch (e) {
      emit(BrowseError(e.toString()));
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
}
