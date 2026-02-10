import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/message.dart';
import 'message_event.dart';
import 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final ApiService _apiService;

  MessageBloc(this._apiService) : super(MessageInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
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
      emit(MessageError(message: e.toString()));
    }
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
      emit(MessageError(message: e.toString()));
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
      emit(MessageError(message: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _apiService.markMessageAsRead(event.messageId);
      // State update handled by re-loading conversations or messages
    } catch (e) {
      emit(MessageError(message: e.toString()));
    }
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      await _apiService.markConversationAsRead(event.conversationId);
      // State update can be triggered by caller reloading conversations
    } catch (e) {
      // Fail silently for mark as read
    }
  }
}
