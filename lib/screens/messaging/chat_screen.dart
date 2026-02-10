import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/message/message_bloc.dart';
import '../../bloc/message/message_event.dart';
import '../../bloc/message/message_state.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../services/realtime_service.dart';
import '../../services/api_service.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../widgets/user_avatar.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String? conversationTitle;
  final User? otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.conversationTitle,
    this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RealtimeService _realtimeService = RealtimeService();
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    // No need for _getCurrentUser() anymore as we'll get it from bloc
  }


  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await getIt<ApiService>().getMessages(widget.conversationId);
      // Mark as read when opening
      getIt<ApiService>().markConversationAsRead(widget.conversationId).then((_) {
        _realtimeService.triggerUnreadCountSync();
      }).catchError((e) => debugPrint('Error marking read: $e'));
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    // Subscribe to conversation-specific room
    _realtimeService.subscribeToConversation(widget.conversationId);
    
    // Listen for new messages
    _messageSubscription = _realtimeService.messageReceived.listen((data) {
      final messageData = data['message'] ?? data;
      final conversationId = messageData['conversation_id'] ?? messageData['conversationId'];
      
      // Only add messages for this conversation
      if (conversationId == widget.conversationId) {
        final newMessage = Message(
          id: messageData['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderId: messageData['sender_id'] ?? messageData['senderId'] ?? '',
          receiverId: messageData['receiver_id'] ?? messageData['receiverId'] ?? '',
          content: messageData['content'] ?? '',
          timestamp: messageData['created_at'] != null 
              ? DateTime.parse(messageData['created_at'])
              : DateTime.now(),
          read: false,
        );
        
        // Avoid duplicates
        if (!_messages.any((m) => m.id == newMessage.id)) {
          // Mark as read if we are looking at it
          getIt<ApiService>().markConversationAsRead(widget.conversationId).then((_) {
            _realtimeService.triggerUnreadCountSync();
          }).catchError((e) => debugPrint('Error marking read: $e'));
          
          setState(() {
            _messages = [..._messages, newMessage];
          });
          _scrollToBottom();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _realtimeService.unsubscribeFromConversation(widget.conversationId);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final authState = context.read<AuthBloc>().state;
    String? currentId;
    if (authState is AuthAuthenticated) {
      currentId = authState.user.id;
    }

    // Optimistic update - add message immediately
    final optimisticMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: currentId ?? 'currentUser',
      receiverId: widget.otherUserId,
      content: content,
      timestamp: DateTime.now(),
      read: false,
    );

    setState(() {
      _messages = [..._messages, optimisticMessage];
    });
    _scrollToBottom();

    try {
      // Send to server
      final sentMessage = await getIt<ApiService>().sendMessage(Message(
        id: '',
        conversationId: widget.conversationId,
        senderId: currentId ?? '',
        receiverId: widget.otherUserId,
        content: content,
        timestamp: DateTime.now(),
        read: false,
      ));

      // Replace optimistic message with real one
      setState(() {
        _messages = _messages.map((m) => 
          m.id == optimisticMessage.id ? sentMessage : m
        ).toList();
      });
    } catch (e) {
      // Remove optimistic message on error
      setState(() {
        _messages = _messages.where((m) => m.id != optimisticMessage.id).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.otherUser != null)
              UserAvatar.fromUser(widget.otherUser!, radius: 16, badgeSize: 12)
            else
              UserAvatar(
                name: widget.otherUserName,
                profileImage: widget.otherUserImage,
                radius: 16,
                badgeSize: 12,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversationTitle ?? widget.otherUserName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.conversationTitle != null)
                    Text(
                      widget.otherUserName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    )
                  else
                    Text(
                      _realtimeService.isConnected ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: _realtimeService.isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet. Start the conversation!'),
                      )
                    : BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          String? currentUserId;
                          if (authState is AuthAuthenticated) {
                            currentUserId = authState.user.id;
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.senderId == currentUserId;
                              final showTime = index == 0 ||
                                  _messages[index - 1].timestamp.difference(message.timestamp).inMinutes.abs() > 30;

                              return Padding(
                                padding: EdgeInsets.only(
                                  left: isMe ? 48 : 0,
                                  right: isMe ? 0 : 48,
                                  bottom: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (showTime)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              DateFormat('MMM d, h:mm a').format(message.timestamp),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Row(
                                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (!isMe) ...[
                                          if (widget.otherUser != null)
                                            UserAvatar.fromUser(widget.otherUser!, radius: 14, badgeSize: 10)
                                          else
                                            UserAvatar(
                                              name: widget.otherUserName,
                                              profileImage: widget.otherUserImage,
                                              radius: 14,
                                              badgeSize: 10,
                                            ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isMe 
                                                  ? AppTheme.navy 
                                                  : Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(20),
                                                topRight: const Radius.circular(20),
                                                bottomLeft: Radius.circular(isMe ? 20 : 4),
                                                bottomRight: Radius.circular(isMe ? 4 : 20),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: isMe 
                                                  ? null 
                                                  : Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message.content,
                                                  style: TextStyle(
                                                    color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                                                    fontSize: 15,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      DateFormat('h:mm a').format(message.timestamp),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isMe 
                                                            ? Colors.white.withOpacity(0.7) 
                                                            : Colors.grey.shade500,
                                                      ),
                                                    ),
                                                    if (isMe) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        message.read ? Icons.done_all : Icons.done,
                                                        size: 14,
                                                        color: message.read 
                                                            ? Colors.lightBlueAccent 
                                                            : Colors.white.withOpacity(0.7),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.navy,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

