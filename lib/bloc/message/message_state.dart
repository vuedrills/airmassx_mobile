import 'package:equatable/equatable.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {}

class ConversationsLoading extends MessageState {}

class ConversationsLoaded extends MessageState {
  final List<Conversation> conversations;

  const ConversationsLoaded({required this.conversations});

  @override
  List<Object?> get props => [conversations];
}

class MessagesLoading extends MessageState {}

class MessagesLoaded extends MessageState {
  final List<Message> messages;
  final String conversationId;

  const MessagesLoaded({
    required this.messages,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [messages, conversationId];
}

class MessageSending extends MessageState {}

class MessageSent extends MessageState {
  final Message message;

  const MessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageError extends MessageState {
  final String message;

  const MessageError({required this.message});

  @override
  List<Object?> get props => [message];
}
