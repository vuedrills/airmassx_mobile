import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../bloc/task/task_bloc.dart';
import '../../bloc/task/task_event.dart';
import '../../bloc/task/task_state.dart';
import '../../models/task.dart';
import '../../widgets/task/task_card.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _selectedFilter = 'All tasks';
  
  final List<String> _filterOptions = [
    'All tasks',
    'Posted',
    'Assigned',
    'Booking Requests',
    'Offered',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    // Load user's tasks
    context.read<TaskBloc>().add(const TaskLoadMyTasks());
  }

  List<Task> _filterTasks(List<Task> tasks) {
    // 1. apply global visibility rules
    final visibleTasks = tasks.where((t) {
      // Rule: Completed tasks only visible for 14 days
      if (t.status == 'completed') {
        final date = t.updatedAt ?? t.createdAt;
        final difference = DateTime.now().difference(date);
        if (difference.inDays > 14) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_selectedFilter) {
      case 'Posted':
        return visibleTasks.where((t) => t.status == 'open' || t.status == 'posted').toList();
      case 'Assigned':
        return visibleTasks.where((t) => t.status == 'assigned' || t.status == 'in_progress').toList();
      case 'Booking Requests':
        return visibleTasks.where((t) => t.status == 'pending').toList();
      case 'Offered':
        return visibleTasks.where((t) => t.offersCount > 0).toList();
      case 'Completed':
        return visibleTasks.where((t) => t.status == 'completed').toList();
      default:
        return visibleTasks;
    }
  }

  Map<String, List<Task>> _groupTasksByStatus(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    
    for (var task in tasks) {
      String groupKey;
      if (task.status == 'cancelled') {
        groupKey = 'CANCELLED TASKS';
      } else if (task.status == 'completed') {
        groupKey = 'COMPLETED TASKS';
      } else if (task.status == 'assigned' || task.status == 'in_progress') {
        groupKey = 'ACTIVE TASKS'; // Assigned & In Progress
      } else {
        groupKey = 'POSTED TASKS'; // Open
      }
      
      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(task);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My tasks',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
        ],
      ),
      body: Column(
        children: [
          // Filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                  itemBuilder: (context) => _filterOptions
                      .map((option) => PopupMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.navy,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Task list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<TaskBloc>().add(const TaskLoadMyTasks());
                // Wait for the bloc to emit a non-loading state
                await context.read<TaskBloc>().stream.firstWhere(
                  (s) => !s.isLoading,
                );
              },
              color: AppTheme.navy,
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(child: Text('Error: ${state.error}')),
                      ],
                    );
                  }

                  final filteredTasks = _filterTasks(state.myTasks);
                  final groupedTasks = _groupTasksByStatus(filteredTasks);

                  if (filteredTasks.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/create-task'),
                                icon: const Icon(Icons.add_rounded, color: Colors.white),
                                label: const Text('Post a Task'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: groupedTasks.length,
                    itemBuilder: (context, index) {
                      final groupKey = groupedTasks.keys.elementAt(index);
                      final tasks = groupedTasks[groupKey]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                            child: Text(
                              groupKey,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Tasks in this group
                          ...tasks.map((task) => TaskCard(task: task)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

