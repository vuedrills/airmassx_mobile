import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../bloc/message/message_bloc.dart';
import '../../bloc/message/message_event.dart';
import '../../bloc/message/message_state.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import 'chat_screen.dart';

import 'dart:async';
import '../notifications/notifications_screen.dart';
import '../../services/realtime_service.dart';
import '../../services/api_service.dart';
import '../../widgets/user_avatar.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;
  StreamSubscription<void>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCounts();
    
    // Listen for sync triggers from RealtimeService
    _syncSubscription = getIt<RealtimeService>().syncUnreadCount.listen((_) {
      _loadUnreadCounts();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final apiService = getIt<ApiService>();
      final msgCount = await apiService.getUnreadMessageCount();
      final notifyCount = await apiService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadMessageCount = msgCount;
          _unreadNotificationCount = notifyCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts in ConversationsScreen: $e');
    }
  }

  Widget _buildTabBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inbox'),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('MESSAGES'),
                    if (_unreadMessageCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildTabBadge(_unreadMessageCount),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('NOTIFICATIONS'),
                    if (_unreadNotificationCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildTabBadge(_unreadNotificationCount),
                    ],
                  ],
                ),
              ),
            ],
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppTheme.navy,
            unselectedLabelColor: AppTheme.neutral400,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.2),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ),
        body: TabBarView(
          children: [
            _buildConversationsTab(),
            const NotificationsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsTab() {
    return BlocProvider(
      create: (_) => getIt<MessageBloc>()..add(const LoadConversations()),
      child: BlocBuilder<MessageBloc, MessageState>(
        builder: (context, state) {
          if (state is ConversationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MessageError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is ConversationsLoaded) {
            final conversations = state.conversations;

            if (conversations.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textSecondary),
                    SizedBox(height: 16),
                    Text('No conversations yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<MessageBloc>().add(const LoadConversations());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppTheme.navy,
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return ListTile(
                    leading: conversation.otherUserDetail != null
                        ? UserAvatar.fromUser(
                            conversation.otherUserDetail!,
                            radius: 20,
                            badgeSize: 14,
                          )
                        : UserAvatar(
                            name: conversation.otherUserName,
                            profileImage: conversation.otherUserImage,
                            radius: 20,
                            isVerified: false, // Default if detail is missing
                            badgeSize: 14,
                          ),
                    title: Text(
                      conversation.taskTitle ?? conversation.otherUserName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (conversation.taskTitle != null)
                          Text(
                            conversation.otherUserName,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        Text(
                          conversation.lastMessage ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conversation.unreadCount > 0 ? AppTheme.navy : AppTheme.textSecondary,
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (conversation.lastMessageTime != null)
                          Text(
                            timeago.format(conversation.lastMessageTime!),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.navy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: conversation.id,
                            otherUserId: conversation.otherUserId,
                            otherUserName: conversation.otherUserName,
                            otherUserImage: conversation.otherUserImage,
                            conversationTitle: conversation.taskTitle,
                            otherUser: conversation.otherUserDetail,
                          ),
                        ),
                      );
                      // Refresh when coming back
                      if (context.mounted) {
                        context.read<MessageBloc>().add(const LoadConversations());
                        _loadUnreadCounts();
                      }
                    },
                  );
                },
              ),
            );
          }

          return const Center(child: Text('No conversations'));
        },
      ),
    );
  }
}
