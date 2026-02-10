import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String reviewerAvatar;
  final double rating;
  final String comment;
  final DateTime date;
  final String? taskTitle;
  final String? reply;
  final DateTime? replyCreatedAt;
  final List<String> _images;

  List<String> get images => _images;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.rating,
    required this.comment,
    required this.date,
    this.reply,
    this.replyCreatedAt,
    this.taskTitle,
    List<String>? images,
  }) : _images = images ?? const <String>[];

  factory Review.fromJson(Map<String, dynamic> json) {
    // Backend may send reviewer as a nested object
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    final task = json['task'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] ?? json['reviewerId'] ?? '',
      reviewerName: reviewer?['name'] ?? json['reviewerName'] ?? '',
      reviewerAvatar: reviewer?['avatar_url'] ?? json['reviewerAvatar'] ?? '',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      date: DateTime.parse(json['created_at'] ?? json['date']),
      reply: json['reply'] as String?,
      replyCreatedAt: json['reply_created_at'] != null ? DateTime.parse(json['reply_created_at']) : null,
      taskTitle: task?['title'] ?? json['taskTitle'] as String?,
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_id': reviewerId,
      'reviewerName': reviewerName,
      'reviewerAvatar': reviewerAvatar,
      'rating': rating,
      'comment': comment,
      'created_at': date.toIso8601String(),
      'reply': reply,
      'reply_created_at': replyCreatedAt?.toIso8601String(),
      'taskTitle': taskTitle,
      'images': images,
    };
  }

  @override
  List<Object?> get props => [
        id,
        reviewerId,
        reviewerName,
        reviewerAvatar,
        rating,
        comment,
        date,
        reply,
        replyCreatedAt,
        taskTitle,
        images,
      ];
}
