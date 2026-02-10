/// Escrow status constants
class EscrowStatus {
  static const String held = 'held';
  static const String released = 'released';
  static const String refunded = 'refunded';
  static const String partial = 'partial';
  static const String disputed = 'disputed';
  static const String cancelled = 'cancelled';
}

class EscrowTransaction {
  final String id;
  final String taskId;
  final String offerId;
  final String posterId;
  final String taskerId;
  final double amount;
  final double commissionRate;
  final double commissionAmount;
  final double taskerAmount;
  final double releasedAmount;
  final double refundedAmount;
  final String status;
  final String? notes;
  final DateTime? releasedAt;
  final DateTime? refundedAt;
  final String? releaseReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated relationships
  final Map<String, dynamic>? task;
  final Map<String, dynamic>? poster;
  final Map<String, dynamic>? tasker;

  EscrowTransaction({
    required this.id,
    required this.taskId,
    required this.offerId,
    required this.posterId,
    required this.taskerId,
    required this.amount,
    this.commissionRate = 0.03,
    this.commissionAmount = 0,
    this.taskerAmount = 0,
    this.releasedAmount = 0,
    this.refundedAmount = 0,
    required this.status,
    this.notes,
    this.releasedAt,
    this.refundedAt,
    this.releaseReason,
    required this.createdAt,
    required this.updatedAt,
    this.task,
    this.poster,
    this.tasker,
  });

  factory EscrowTransaction.fromJson(Map<String, dynamic> json) {
    return EscrowTransaction(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      offerId: json['offer_id'] as String? ?? '',
      posterId: json['poster_id'] as String? ?? '',
      taskerId: json['tasker_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.03,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0,
      taskerAmount: (json['tasker_amount'] as num?)?.toDouble() ?? 0,
      releasedAmount: (json['released_amount'] as num?)?.toDouble() ?? 0,
      refundedAmount: (json['refunded_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'held',
      notes: json['notes'] as String?,
      releasedAt: json['released_at'] != null
          ? DateTime.parse(json['released_at'] as String)
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'] as String)
          : null,
      releaseReason: json['release_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      task: json['task'] as Map<String, dynamic>?,
      poster: json['poster'] as Map<String, dynamic>?,
      tasker: json['tasker'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'offer_id': offerId,
      'poster_id': posterId,
      'tasker_id': taskerId,
      'amount': amount,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'tasker_amount': taskerAmount,
      'released_amount': releasedAmount,
      'refunded_amount': refundedAmount,
      'status': status,
      'notes': notes,
      'released_at': releasedAt?.toIso8601String(),
      'refunded_at': refundedAt?.toIso8601String(),
      'release_reason': releaseReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isHeld => status == EscrowStatus.held;
  bool get isReleased => status == EscrowStatus.released;
  bool get isRefunded => status == EscrowStatus.refunded;
  bool get isDisputed => status == EscrowStatus.disputed;

  String get displayStatus {
    switch (status) {
      case EscrowStatus.held:
        return 'Held in Escrow';
      case EscrowStatus.released:
        return 'Released';
      case EscrowStatus.refunded:
        return 'Refunded';
      case EscrowStatus.partial:
        return 'Partially Released';
      case EscrowStatus.disputed:
        return 'Under Dispute';
      case EscrowStatus.cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  String? get taskTitle => task?['title'] as String?;
  String? get posterName => poster?['name'] as String?;
  String? get taskerName => tasker?['name'] as String?;
}

class EscrowEvent {
  final String id;
  final String escrowId;
  final String event;
  final double? amount;
  final String? actorId;
  final String? notes;
  final DateTime createdAt;

  EscrowEvent({
    required this.id,
    required this.escrowId,
    required this.event,
    this.amount,
    this.actorId,
    this.notes,
    required this.createdAt,
  });

  factory EscrowEvent.fromJson(Map<String, dynamic> json) {
    return EscrowEvent(
      id: json['id'] as String? ?? '',
      escrowId: json['escrow_id'] as String? ?? '',
      event: json['event'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      actorId: json['actor_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get displayEvent {
    switch (event) {
      case 'created':
        return 'Escrow Created';
      case 'funded_from_wallet':
        return 'Funds Deposited';
      case 'release_approved':
        return 'Release Approved';
      case 'released':
        return 'Funds Released';
      case 'refund_requested':
        return 'Refund Requested';
      case 'refunded':
        return 'Funds Refunded';
      case 'disputed':
        return 'Dispute Filed';
      case 'dispute_resolved':
        return 'Dispute Resolved';
      case 'release_requested':
        return 'Release Requested';
      case 'admin_released':
        return 'Admin Released';
      case 'admin_refunded':
        return 'Admin Refunded';
      default:
        return event;
    }
  }
}
