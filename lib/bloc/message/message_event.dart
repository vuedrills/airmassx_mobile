
abstract class MessageEvent {
  const MessageEvent();
}

class LoadConversations extends MessageEvent {
  const LoadConversations();
}

class LoadMessages extends MessageEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);
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
}

class MarkAsRead extends MessageEvent {
  final String messageId;
  const MarkAsRead(this.messageId);
}

class MarkConversationAsRead extends MessageEvent {
  final String conversationId;
  const MarkConversationAsRead(this.conversationId);
}

class ReceiveMessage extends MessageEvent {
  final Map<String, dynamic> data;
  const ReceiveMessage(this.data);
}
