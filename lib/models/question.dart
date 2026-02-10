import 'package:equatable/equatable.dart';
import 'user.dart';

/// Question model for task questions
class Question extends Equatable {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final String? userImage;
  final String question;
  final DateTime timestamp;
  final String? answer;
  final DateTime? answerTimestamp;
  final bool isVerified;
  final User? user;

  const Question({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.question,
    required this.timestamp,
    this.answer,
    this.answerTimestamp,
    this.isVerified = false,
    this.user,
  });

  Question copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? userName,
    String? userImage,
    String? question,
    DateTime? timestamp,
    String? answer,
    DateTime? answerTimestamp,
  }) {
    return Question(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      question: question ?? this.question,
      timestamp: timestamp ?? this.timestamp,
      answer: answer ?? this.answer,
      answerTimestamp: answerTimestamp ?? this.answerTimestamp,
      isVerified: isVerified ?? this.isVerified,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'question': question,
      'timestamp': timestamp.toIso8601String(),
      'answer': answer,
      'answerTimestamp': answerTimestamp?.toIso8601String(),
      'isVerified': isVerified,
      'user': user?.toJson(),
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userImage: json['userImage'] as String?,
      question: json['question'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      answerTimestamp: json['answerTimestamp'] != null 
          ? DateTime.parse(json['answerTimestamp'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        userId,
        userName,
        userImage,
        question,
        timestamp,
        answer,
        answerTimestamp,
        isVerified,
      ];
}
