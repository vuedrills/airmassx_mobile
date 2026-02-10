import 'package:equatable/equatable.dart';

/// Transaction types
enum TransactionType {
  payment,
  refund,
  withdrawal,
  deposit,
}

/// Transaction status
enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

/// Payment transaction model
class PaymentTransaction extends Equatable {
  final String id;
  final String taskId;
  final String taskTitle;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime date;
  final String? paymentMethodId;
  final String? description;

  const PaymentTransaction({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    this.paymentMethodId,
    this.description,
  });

  PaymentTransaction copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? date,
    String? paymentMethodId,
    String? description,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      date: date ?? this.date,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'date': date.toIso8601String(),
      'paymentMethodId': paymentMethodId,
      'description': description,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.byName(json['type'] as String),
      status: TransactionStatus.values.byName(json['status'] as String),
      date: DateTime.parse(json['date'] as String),
      paymentMethodId: json['paymentMethodId'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        taskTitle,
        amount,
        type,
        status,
        date,
        paymentMethodId,
        description,
      ];
}
