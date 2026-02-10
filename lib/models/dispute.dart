/// Dispute status constants
class DisputeStatus {
  static const String open = 'open';
  static const String underReview = 'under_review';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
  static const String escalated = 'escalated';
}

/// Dispute reason constants
class DisputeReason {
  static const String workQuality = 'work_quality';
  static const String payment = 'payment';
  static const String noShow = 'no_show';
  static const String communication = 'communication';
  static const String scopeChange = 'scope_change';
  static const String propertyDamage = 'property_damage';
  static const String safety = 'safety';
  static const String other = 'other';

  static String getDisplayName(String reason) {
    switch (reason) {
      case workQuality:
        return 'Work Quality';
      case payment:
        return 'Payment Issue';
      case noShow:
        return 'No Show';
      case communication:
        return 'Communication';
      case scopeChange:
        return 'Scope Change';
      case propertyDamage:
        return 'Property Damage';
      case safety:
        return 'Safety Concern';
      case other:
        return 'Other';
      default:
        return reason;
    }
  }

  static List<Map<String, String>> getAllReasons() {
    return [
      {'id': workQuality, 'name': 'Work Quality', 'description': 'The quality of work did not meet expectations'},
      {'id': payment, 'name': 'Payment Issue', 'description': 'Issues with payment or pricing'},
      {'id': noShow, 'name': 'No Show', 'description': 'The other party did not show up'},
      {'id': communication, 'name': 'Communication', 'description': 'Poor or no communication'},
      {'id': scopeChange, 'name': 'Scope Change', 'description': 'Unauthorized changes to scope of work'},
      {'id': propertyDamage, 'name': 'Property Damage', 'description': 'Damage to property occurred'},
      {'id': safety, 'name': 'Safety Concern', 'description': 'Safety issues or hazards'},
      {'id': other, 'name': 'Other', 'description': 'Other issue not listed above'},
    ];
  }
}

class Dispute {
  final String id;
  final String taskId;
  final String initiatorId;
  final String respondentId;
  final String reason;
  final String description;
  final List<String> evidenceUrls;
  final String status;
  final String priority;
  final String? assignedAdminId;
  final String? adminNotes;
  final String? resolution;
  final String? resolutionNotes;
  final double? refundAmount;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated relationships
  final Map<String, dynamic>? task;
  final Map<String, dynamic>? initiator;
  final Map<String, dynamic>? respondent;

  Dispute({
    required this.id,
    required this.taskId,
    required this.initiatorId,
    required this.respondentId,
    required this.reason,
    required this.description,
    this.evidenceUrls = const [],
    required this.status,
    required this.priority,
    this.assignedAdminId,
    this.adminNotes,
    this.resolution,
    this.resolutionNotes,
    this.refundAmount,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.task,
    this.initiator,
    this.respondent,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      initiatorId: json['initiator_id'] as String? ?? '',
      respondentId: json['respondent_id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String? ?? '',
      evidenceUrls: (json['evidence_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String? ?? 'normal',
      assignedAdminId: json['assigned_admin_id'] as String?,
      adminNotes: json['admin_notes'] as String?,
      resolution: json['resolution'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      refundAmount: (json['refund_amount'] as num?)?.toDouble(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      task: json['task'] as Map<String, dynamic>?,
      initiator: json['initiator'] as Map<String, dynamic>?,
      respondent: json['respondent'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'initiator_id': initiatorId,
      'respondent_id': respondentId,
      'reason': reason,
      'description': description,
      'evidence_urls': evidenceUrls,
      'status': status,
      'priority': priority,
      'assigned_admin_id': assignedAdminId,
      'admin_notes': adminNotes,
      'resolution': resolution,
      'resolution_notes': resolutionNotes,
      'refund_amount': refundAmount,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOpen => status == DisputeStatus.open;
  bool get isUnderReview => status == DisputeStatus.underReview;
  bool get isResolved => status == DisputeStatus.resolved;
  bool get isClosed => status == DisputeStatus.closed;

  String get displayStatus {
    switch (status) {
      case DisputeStatus.open:
        return 'Open';
      case DisputeStatus.underReview:
        return 'Under Review';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.closed:
        return 'Closed';
      case DisputeStatus.escalated:
        return 'Escalated';
      default:
        return status;
    }
  }

  String get displayReason => DisputeReason.getDisplayName(reason);

  String? get taskTitle => task?['title'] as String?;
  String? get initiatorName => initiator?['name'] as String?;
  String? get respondentName => respondent?['name'] as String?;
}

class DisputeMessage {
  final String id;
  final String disputeId;
  final String senderId;
  final String message;
  final bool isAdmin;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  DisputeMessage({
    required this.id,
    required this.disputeId,
    required this.senderId,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
    this.sender,
  });

  factory DisputeMessage.fromJson(Map<String, dynamic> json) {
    return DisputeMessage(
      id: json['id'] as String? ?? '',
      disputeId: json['dispute_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      sender: json['sender'] as Map<String, dynamic>?,
    );
  }

  String? get senderName => sender?['name'] as String?;
}
