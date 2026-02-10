import 'user.dart';

class Offer {
  final String id;
  final String taskId;
  final String taskerId;
  final double? amount;
  final String message;
  final String status;
  final DateTime createdAt;
  
  // Additional fields for UI
  final String? taskerName;
  final String? taskerImage;
  final bool? taskerVerified;
  final double? taskerRating;
  final int? taskerCompletedTasks;
  final bool? isNew; // For new users
  final int? reviewCount; // Number of reviews
  final int? completionRate; // Completion rate percentage (0-100)
  final int? rebookCount; // Number of times rebooked
  final String? availability; // e.g., "Today · Tomorrow", "This weekend"
  final String? invoiceUrl;
  final String? invoiceFileName;
  final User? tasker;

  Offer({
    required this.id,
    required this.taskId,
    required this.taskerId,
    this.amount,
    required this.message,
    required this.status,
    required this.createdAt,
    this.taskerName,
    this.taskerImage,
    this.taskerVerified,
    this.taskerRating,
    this.taskerCompletedTasks,
    this.isNew,
    this.reviewCount,
    this.completionRate,
    this.rebookCount,
    this.availability,
    this.invoiceUrl,
    this.invoiceFileName,
    this.tasker,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskerId: json['tasker_id'] as String,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      message: json['message'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      taskerName: json['tasker_name'] as String?,
      taskerImage: json['tasker_image'] as String?,
      taskerVerified: json['tasker_verified'] as bool?,
      taskerRating: (json['tasker_rating'] as num?)?.toDouble(),
      taskerCompletedTasks: json['tasker_completed_tasks'] as int?,
      isNew: json['is_new'] as bool?,
      reviewCount: json['review_count'] as int?,
      completionRate: json['completion_rate'] as int?,
      rebookCount: json['rebook_count'] as int?,
      availability: json['availability'] as String?,
      invoiceUrl: json['invoice_url'] as String?,
      invoiceFileName: json['invoice_file_name'] as String?,
      tasker: json['tasker'] != null ? User.fromJson(json['tasker']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'tasker_id': taskerId,
      'amount': amount,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'tasker_name': taskerName,
      'tasker_image': taskerImage,
      'tasker_verified': taskerVerified,
      'tasker_rating': taskerRating,
      'tasker_completed_tasks': taskerCompletedTasks,
      'is_new': isNew,
      'review_count': reviewCount,
      'completion_rate': completionRate,
      'rebook_count': rebookCount,
      'availability': availability,
      'invoice_url': invoiceUrl,
      'invoice_file_name': invoiceFileName,
      'tasker': tasker?.toJson(),
    };
  }
}
