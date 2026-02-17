import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../models/message.dart';
import '../../models/conversation.dart';
import '../../core/error_handler.dart';
import 'message_event.dart';
import 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final ApiService _apiService;
  final RealtimeService _realtimeService;
  StreamSubscription? _messageSubscription;

  MessageBloc(this._apiService, this._realtimeService) : super(MessageInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
    on<ReceiveMessage>(_onReceiveMessage);

    _messageSubscription = _realtimeService.messageReceived.listen((data) {
      add(ReceiveMessage(data));
    });
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessageState> emit,
  ) async {
    emit(ConversationsLoading());
    try {
      final conversations = await _apiService.getConversations();
      emit(ConversationsLoaded(conversations: conversations));
    } catch (e) {
      emit(MessageError(message: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Future<void> _onReceiveMessage(
    ReceiveMessage event,
    Emitter<MessageState> emit,
  ) async {
    try {
      final data = event.data;
      final messageData = data['message'] is Map<String, dynamic> ? data['message'] : data;
      
      if (messageData == null || (messageData['content'] == null && messageData['text'] == null)) return;

      final newMessage = Message.fromJson(messageData);

      if (state is ConversationsLoaded) {
        final currentState = state as ConversationsLoaded;
        final conversations = List<Conversation>.from(currentState.conversations);
        
        final index = conversations.indexWhere((c) => c.id == newMessage.conversationId);
        if (index != -1) {
          final oldConv = conversations[index];
          final isFromOther = newMessage.senderId == oldConv.otherUserId;
          
          conversations[index] = oldConv.copyWith(
            lastMessage: newMessage.content,
            lastMessageTime: newMessage.timestamp,
            unreadCount: isFromOther ? oldConv.unreadCount + 1 : oldConv.unreadCount,
          );

          final movedConv = conversations.removeAt(index);
          conversations.insert(0, movedConv);
          
          emit(ConversationsLoaded(conversations: conversations));
        } else {
          add(const LoadConversations());
        }
      } else if (state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        if (currentState.conversationId == newMessage.conversationId) {
          if (!currentState.messages.any((m) => m.id == newMessage.id)) {
            final messages = List<Message>.from(currentState.messages);
            messages.add(newMessage);
            emit(MessagesLoaded(
              messages: messages,
              conversationId: currentState.conversationId,
            ));
            add(MarkAsRead(newMessage.id));
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessagesLoading());
    try {
      final messages = await _apiService.getMessages(event.conversationId);
      emit(MessagesLoaded(
        messages: messages,
        conversationId: event.conversationId,
      ));
    } catch (e) {
      emit(MessageError(message: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageSending());
    try {
      final currentUser = await _apiService.getCurrentUser();
      final message = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: event.conversationId,
        senderId: currentUser?.id ?? 'currentUser',
        receiverId: event.receiverId,
        content: event.content,
        timestamp: DateTime.now(),
        read: false,
      );
      
      await _apiService.sendMessage(message);
      emit(MessageSent(message: message));
      
      // Reload messages after sending
      final messages = await _apiService.getMessages(event.conversationId);
      emit(MessagesLoaded(
        messages: messages,
        conversationId: event.conversationId,
      ));
    } catch (e) {
      emit(MessageError(message: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _apiService.markMessageAsRead(event.messageId);
    } catch (e) {
      emit(MessageError(message: ErrorHandler.getUserFriendlyMessage(e)));
    }
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _apiService.markConversationAsRead(event.conversationId);
    } catch (e) {}
  }
}
