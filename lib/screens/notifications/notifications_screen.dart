import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../messaging/chat_screen.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showAppBar;
  const NotificationsScreen({super.key, this.showAppBar = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _error;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenForRealtimeNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _listenForRealtimeNotifications() {
    final realtimeService = getIt<RealtimeService>();
    _notificationSubscription = realtimeService.notifications.listen((data) {
      // Add the new notification to the top of the list
      if (mounted) {
        setState(() {
          // Convert the notification data to match the expected format
          final newNotification = {
            'id': data['id'] ?? data['ID'],
            'user_id': data['user_id'] ?? data['UserID'],
            'type': data['type'] ?? data['Type'] ?? 'info',
            'title': data['title'] ?? data['Title'] ?? 'Notification',
            'message': data['message'] ?? data['Message'] ?? '',
            'data': data['data'] ?? data['Data'],
            'is_read': data['is_read'] ?? data['IsRead'] ?? false,
            'created_at': data['created_at'] ?? data['CreatedAt'] ?? DateTime.now().toIso8601String(),
          };
          // Add to top of list, avoiding duplicates
          final existingIndex = _notifications.indexWhere((n) => n['id'] == newNotification['id']);
          if (existingIndex == -1) {
            _notifications.insert(0, newNotification);
          }
        });
      }
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = getIt<ApiService>();
      final notifications = await apiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notifications';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      return Container(
        color: Colors.white,
        child: _buildBody(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0E1638),
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            TextButton(
              onPressed: _loadNotifications,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 48,
                color: AppTheme.navy.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0E1638),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll let you know when something\nimportant happens.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.navy,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final bool isRead = notification['is_read'] ?? notification['read'] ?? false;
    final String title = notification['title'] ?? 'Notification';
    final String message = notification['message'] ?? notification['content'] ?? '';
    final DateTime? createdAt = notification['created_at'] != null 
        ? DateTime.parse(notification['created_at']) 
        : null;
    final String type = notification['type'] ?? 'info';

    IconData icon;
    Color color;

    switch (type) {
      case 'offer':
      case 'new_offer':
        icon = Icons.local_offer_outlined;
        color = Colors.green;
        break;
      case 'offer_accepted':
        icon = Icons.check_circle_outline;
        color = Colors.green.shade700;
        break;
      case 'offer_accepted_by_you':
        icon = Icons.handshake_outlined;
        color = Colors.teal;
        break;
      case 'message':
      case 'new_message':
        icon = Icons.chat_bubble_outline;
        color = Colors.blue;
        break;
      case 'task_update':
      case 'task_completed':
        icon = Icons.assignment_turned_in_outlined;
        color = Colors.orange;
        break;
      case 'review_received':
        icon = Icons.star_outline;
        color = Colors.amber.shade700;
        break;
      case 'payment':
        icon = Icons.payment_outlined;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications_none_outlined;
        color = AppTheme.navy;
    }

    // Extract task and conversation IDs for use in both onTap and message button
    final dynamic rawData = notification['data'];
    Map<String, dynamic> extraData = {};
    
    if (rawData != null) {
      if (rawData is Map) {
        extraData = rawData.cast<String, dynamic>();
      } else if (rawData is String) {
        try {
          extraData = jsonDecode(rawData);
        } catch (e) {
          debugPrint('Error parsing notification data: $e');
        }
      }
    }

    final String? taskId = extraData['task_id'] ?? extraData['taskId'] ?? notification['task_id'];
    final String? conversationId = extraData['conversation_id'] ?? extraData['conversationId'] ?? notification['conversation_id'];

    return InkWell(
      onTap: () {
        if (type == 'new_offer' || type == 'task_update' || type == 'task_completed' || 
            type == 'offer_accepted' || type == 'offer_accepted_by_you' || type == 'review_received') {
          if (taskId != null) {
            context.push('/tasks/$taskId');
          }
        } else if (type == 'message' || type == 'new_message') {
          if (conversationId != null) {
            _handleMessageButton(conversationId, taskId);
          }
        } else if (type == 'dispute') {
          final String? disputeId = extraData['dispute_id'] ?? extraData['reference_id'] ?? notification['reference_id'];
          if (disputeId != null) {
            context.push('/profile/disputes/$disputeId');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        color: isRead ? Colors.transparent : AppTheme.navy.withOpacity(0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0E1638),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (createdAt != null)
                        Text(
                          _formatTimeAgo(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRead ? Colors.grey.shade600 : Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                  if (conversationId != null || taskId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () => _handleMessageButton(conversationId, taskId),
                        icon: const Icon(Icons.message_outlined, size: 16),
                        label: const Text('Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppTheme.navy,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(left: 12, top: 12),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.navy,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMessageButton(String? conversationId, String? taskId) async {
    try {
      final apiService = getIt<ApiService>();
      
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading conversation...'),
          duration: Duration(seconds: 1),
        ),
      );

      final conversations = await apiService.getConversations();
      final conversation = conversations.firstWhere(
        (c) => (conversationId != null && c.id == conversationId) || 
               (taskId != null && c.taskId == taskId),
        orElse: () => throw Exception('Conversation not found'),
      );

      // Fetch task to get the title
      String? taskTitle;
      if (conversation.taskId.isNotEmpty) {
        final task = await apiService.getTaskById(conversation.taskId);
        taskTitle = task?.title;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              otherUserId: conversation.otherUserId,
              otherUserName: conversation.otherUserName,
              otherUserImage: conversation.otherUserImage,
              conversationTitle: taskTitle,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open conversation: ${e.toString()}'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays > 7) {
        return DateFormat('MMM d').format(dateTime);
      }
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
