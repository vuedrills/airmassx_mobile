import 'package:equatable/equatable.dart';

class InvoiceItem extends Equatable {
  final String description;
  final int quantity;
  final double unitPrice;

  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  @override
  List<Object?> get props => [description, quantity, unitPrice];
}

class Invoice extends Equatable {
  final String id;
  final String taskId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final List<InvoiceItem> items;
  final DateTime issueDate;
  final DateTime dueDate;
  final String status; // 'draft', 'sent', 'paid'
  final String? qrCodeData;

  const Invoice({
    required this.id,
    required this.taskId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.items,
    required this.issueDate,
    required this.dueDate,
    this.status = 'draft',
    this.qrCodeData,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: json['status'] as String,
      qrCodeData: json['qrCodeData'] as String?,
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
      'items': items.map((e) => e.toJson()).toList(),
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'qrCodeData': qrCodeData,
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
        items,
        issueDate,
        dueDate,
        status,
        qrCodeData,
      ];
}
