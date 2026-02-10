import 'package:equatable/equatable.dart';

/// Payment method types
enum PaymentType {
  card,
  bankAccount,
  paypal,
}

/// Payment method model
class PaymentMethod extends Equatable {
  final String id;
  final PaymentType type;
  final String displayName;
  final bool isDefault;
  final String? cardLast4;
  final String? cardBrand;
  final DateTime? expiryDate;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    this.isDefault = false,
    this.cardLast4,
    this.cardBrand,
    this.expiryDate,
  });

  PaymentMethod copyWith({
    String? id,
    PaymentType? type,
    String? displayName,
    bool? isDefault,
    String? cardLast4,
    String? cardBrand,
    DateTime? expiryDate,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      isDefault: isDefault ?? this.isDefault,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'displayName': displayName,
      'isDefault': isDefault,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: PaymentType.values.byName(json['type'] as String),
      displayName: json['displayName'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      cardLast4: json['cardLast4'] as String?,
      cardBrand: json['cardBrand'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        displayName,
        isDefault,
        cardLast4,
        cardBrand,
        expiryDate,
      ];
}
