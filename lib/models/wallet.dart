class Wallet {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final String type; // credit, debit, topup, commission_debit
  final double amount;
  final String? reference;
  final String? paynowReference;
  final String? pollUrl;
  final String status; // pending, completed, failed
  final String? paymentMethod;
  final String? phone;
  final String? browserUrl;
  final String? authorizationCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.reference,
    this.paynowReference,
    this.pollUrl,
    required this.status,
    this.paymentMethod,
    this.phone,
    this.browserUrl,
    this.authorizationCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reference: json['reference'] as String?,
      paynowReference: json['paynow_reference'] as String?,
      pollUrl: json['poll_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      phone: json['phone'] as String?,
      browserUrl: json['browser_url'] as String?,
      authorizationCode: json['authorization_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'reference': reference,
      'paynow_reference': paynowReference,
      'poll_url': pollUrl,
      'status': status,
      'payment_method': paymentMethod,
      'phone': phone,
      'browser_url': browserUrl,
      'authorization_code': authorizationCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  String get displayType {
    switch (type) {
      case 'topup':
        return 'Top Up';
      case 'commission_debit':
        return 'Commission';
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return type;
    }
  }

  String get displayPaymentMethod {
    switch (paymentMethod) {
      case 'ecocash':
        return 'EcoCash';
      case 'onemoney':
        return 'OneMoney';
      case 'innbucks':
        return 'InnBucks';
      case 'omari':
        return "O'mari";
      default:
        return paymentMethod ?? '';
    }
  }
}

/// Withdrawal request model
class WithdrawalRequest {
  final String id;
  final String userId;
  final double amount;
  final double fee;
  final double netAmount;
  final String paymentMethod;
  final String accountNumber;
  final String? accountName;
  final String status; // pending, approved, processing, completed, rejected, failed
  final String? adminNotes;
  final String? rejectionReason;
  final String? transactionRef;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.paymentMethod,
    required this.accountNumber,
    this.accountName,
    required this.status,
    this.adminNotes,
    this.rejectionReason,
    this.transactionRef,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      accountName: json['account_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      transactionRef: json['transaction_ref'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'fee': fee,
      'net_amount': netAmount,
      'payment_method': paymentMethod,
      'account_number': accountNumber,
      'account_name': accountName,
      'status': status,
      'admin_notes': adminNotes,
      'rejection_reason': rejectionReason,
      'transaction_ref': transactionRef,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isFailed => status == 'failed';
  bool get canCancel => status == 'pending';

  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String get displayPaymentMethod {
    switch (paymentMethod) {
      case 'ecocash':
        return 'EcoCash';
      case 'onemoney':
        return 'OneMoney';
      case 'innbucks':
        return 'InnBucks';
      default:
        return paymentMethod;
    }
  }
}
