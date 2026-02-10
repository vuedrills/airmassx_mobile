import 'package:equatable/equatable.dart';
import '../../models/task.dart';

class TaskState extends Equatable {
  final List<Task> tasks; // Browse tasks
  final List<Task> myTasks; // User's own tasks
  final Task? selectedTask;
  final bool isLoading;
  final String? error;
  
  final List<Task> activeTasks; // User is the provider/tasker
  final List<Task> pendingReviews; // Tasks waiting for review
  final bool isCompleting;
  final String? successMessage;
  
  const TaskState({
    this.tasks = const [],
    this.myTasks = const [],
    this.activeTasks = const [],
    this.pendingReviews = const [],
    this.selectedTask,
    this.isLoading = false,
    this.isCompleting = false,
    this.error,
    this.successMessage,
  });
  
  TaskState copyWith({
    List<Task>? tasks,
    List<Task>? myTasks,
    List<Task>? activeTasks,
    List<Task>? pendingReviews,
    Task? selectedTask,
    bool? isLoading,
    bool? isCompleting,
    String? error,
    String? successMessage,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      myTasks: myTasks ?? this.myTasks,
      activeTasks: activeTasks ?? this.activeTasks,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      selectedTask: selectedTask ?? this.selectedTask,
      isLoading: isLoading ?? this.isLoading,
      isCompleting: isCompleting ?? this.isCompleting,
      error: error,
      successMessage: successMessage,
    );
  }
  
  @override
  List<Object?> get props => [tasks, myTasks, activeTasks, pendingReviews, selectedTask, isLoading, isCompleting, error, successMessage];
}
