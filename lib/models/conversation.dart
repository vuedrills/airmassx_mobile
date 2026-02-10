import 'user.dart';

class Conversation {
  final String id;
  final String taskId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? taskTitle;
  final User? otherUserDetail;

  Conversation({
    required this.id,
    required this.taskId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.taskTitle,
    this.otherUserDetail,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserImage': otherUserImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'taskTitle': taskTitle,
      'otherUserDetail': otherUserDetail?.toJson(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      taskId: json['task_id'] as String? ?? json['taskId'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? (json['other_user'] != null ? json['other_user']['id'] : '') as String,
      otherUserName: json['otherUserName'] as String? ?? (json['other_user'] != null ? json['other_user']['name'] : '') as String,
      otherUserImage: json['otherUserImage'] as String? ?? (json['other_user'] != null ? json['other_user']['avatar_url'] : null) as String?,
      lastMessage: json['lastMessage'] as String? ?? json['last_message'] as String?,
      lastMessageTime: (json['lastMessageTime'] ?? json['last_message_at']) != null
          ? DateTime.parse(json['lastMessageTime'] ?? json['last_message_at'])
          : null,
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      taskTitle: json['taskTitle'] ?? (json['task'] != null ? json['task']['title'] : null) as String?,
      otherUserDetail: json['other_user'] != null ? User.fromJson(json['other_user']) : null,
    );
  }

  Conversation copyWith({
    String? id,
    String? taskId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? taskTitle,
    User? otherUserDetail,
  }) {
    return Conversation(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserImage: otherUserImage ?? this.otherUserImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      taskTitle: taskTitle ?? this.taskTitle,
      otherUserDetail: otherUserDetail ?? this.otherUserDetail,
    );
  }
}
