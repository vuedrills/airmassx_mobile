import 'package:equatable/equatable.dart';

class QuoteRequest extends Equatable {
  final String id;
  final String taskId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String message;
  final DateTime createdAt;
  final String status; // 'pending', 'quoted', 'accepted', 'rejected'

  const QuoteRequest({
    required this.id,
    required this.taskId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.message,
    required this.createdAt,
    this.status = 'pending',
  });

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    return QuoteRequest(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        fromUserId,
        fromUserName,
        toUserId,
        toUserName,
        message,
        createdAt,
        status,
      ];
}
