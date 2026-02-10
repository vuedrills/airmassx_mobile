import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final ApiService _apiService;

  TaskBloc(this._apiService) : super(const TaskState()) {
    on<TaskLoadAll>(_onLoadAll);
    on<TaskLoadMyTasks>(_onLoadMyTasks);
    on<TaskLoadActive>(_onLoadActive);
    on<TaskLoadById>(_onLoadById);
    on<TaskApplyFilters>(_onApplyFilters);
    on<TaskComplete>(_onComplete);
    on<TaskLoadPendingReviews>(_onLoadPendingReviews);
  }

  Future<void> _onLoadPendingReviews(
    TaskLoadPendingReviews event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final pending = await _apiService.getPendingReviews();
      emit(state.copyWith(pendingReviews: pending));
    } catch (e) {
      // Don't show hard error for background check
      print('Failed to load pending reviews: $e');
    }
  }

  Future<void> _onLoadActive(
    TaskLoadActive event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final activeTasks = await _apiService.getActiveTasks();
      emit(state.copyWith(activeTasks: activeTasks, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to load active tasks: ${e.toString()}'));
    }
  }

  Future<void> _onComplete(
    TaskComplete event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isCompleting: true));
    try {
      await _apiService.completeTask(event.taskId);
      
      // Refresh active tasks list
      final activeTasks = await _apiService.getActiveTasks();
      
      emit(state.copyWith(
        activeTasks: activeTasks,
        isCompleting: false, 
        successMessage: 'Task marked as complete!',
        error: null,
      ));
      
      // Clear success message after a delay if needed (can be handled in UI)
    } catch (e) {
      emit(state.copyWith(
        isCompleting: false, 
        error: 'Failed to complete task: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadAll(
    TaskLoadAll event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      // Filter for service tasks only - equipment tasks go to Equipment tab
      final tasks = await _apiService.getTasks(taskType: 'service');
      emit(state.copyWith(tasks: tasks, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to load tasks: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMyTasks(
    TaskLoadMyTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final currentUser = await _apiService.getCurrentUser();
      final currentUserId = currentUser?.id ?? '';
      
      if (currentUserId.isEmpty) {
        // If not logged in, load all tasks for demo purposes
        final allTasks = await _apiService.getTasks();
        emit(state.copyWith(myTasks: allTasks.take(5).toList(), isLoading: false, error: null));
        return;
      }
      
      final allTasks = await _apiService.getTasks(posterId: currentUserId);
      emit(state.copyWith(myTasks: allTasks, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to load my tasks: ${e.toString()}'));
    }
  }

  Future<void> _onApplyFilters(
    TaskApplyFilters event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      // Fetch tasks from API - let server handle filtering when possible
      List<Task> filteredTasks = await _apiService.getTasksWithFilter(
        category: event.category,
      );
      
      // Apply client-side filters for features not supported by API
      if (event.minPrice != null) {
        filteredTasks = filteredTasks
            .where((task) => task.budget >= event.minPrice!)
            .toList();
      }
      if (event.maxPrice != null) {
        filteredTasks = filteredTasks
            .where((task) => task.budget <= event.maxPrice!)
            .toList();
      }
      
      // Filter by search query (search in title and description)
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        filteredTasks = filteredTasks.where((task) {
          final titleMatch = task.title.toLowerCase().contains(query);
          final descMatch = task.description.toLowerCase().contains(query);
          final categoryMatch = task.category.toLowerCase().contains(query);
          return titleMatch || descMatch || categoryMatch;
        }).toList();
      }
      
      emit(state.copyWith(tasks: filteredTasks, isLoading: false, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to filter tasks: ${e.toString()}'));
    }
  }

  Future<void> _onLoadById(
    TaskLoadById event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final task = await _apiService.getTaskById(event.taskId);
      if (task != null) {
        emit(state.copyWith(selectedTask: task, isLoading: false, error: null));
      } else {
        emit(state.copyWith(isLoading: false, error: 'Task not found'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to load task: ${e.toString()}'));
    }
  }
}
