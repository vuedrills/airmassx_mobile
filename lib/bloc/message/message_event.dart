import 'package:equatable/equatable.dart';

abstract class MessageEvent extends Equatable {
 const MessageEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends MessageEvent {
  const LoadConversations();
}

class LoadMessages extends MessageEvent {
  final String conversationId;

  const LoadMessages({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends MessageEvent {
  final String conversationId;
  final String receiverId;
  final String content;

  const SendMessage({
    required this.conversationId,
    required this.receiverId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, receiverId, content];
}

class MarkAsRead extends MessageEvent {
  final String messageId;

  const MarkAsRead({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class MarkConversationAsRead extends MessageEvent {
  final String conversationId;

  const MarkConversationAsRead({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}
