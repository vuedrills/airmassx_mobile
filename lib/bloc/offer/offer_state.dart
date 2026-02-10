import 'package:equatable/equatable.dart';

enum OfferStatus { initial, submitting, success, failure }

// Sentinel value to distinguish between "not provided" and "set to null"
const _clearValue = Object();

class OfferState extends Equatable {
  final double amount;
  final String message;
  final String? availability;
  final String? invoiceFilePath;
  final OfferStatus status;
  final String? errorMessage;
  final String? errorCode;

  const OfferState({
    this.amount = 0,
    this.message = '',
    this.availability,
    this.invoiceFilePath,
    this.status = OfferStatus.initial,
    this.errorMessage,
    this.errorCode,
  });

  OfferState copyWith({
    double? amount,
    String? message,
    Object? availability = _clearValue,
    Object? invoiceFilePath = _clearValue,
    OfferStatus? status,
    Object? errorMessage = _clearValue,
    Object? errorCode = _clearValue,
  }) {
    return OfferState(
      amount: amount ?? this.amount,
      message: message ?? this.message,
      availability: availability == _clearValue ? this.availability : availability as String?,
      invoiceFilePath: invoiceFilePath == _clearValue ? this.invoiceFilePath : invoiceFilePath as String?,
      status: status ?? this.status,
      errorMessage: errorMessage == _clearValue ? this.errorMessage : errorMessage as String?,
      errorCode: errorCode == _clearValue ? this.errorCode : errorCode as String?,
    );
  }

  @override
  List<Object?> get props => [amount, message, availability, invoiceFilePath, status, errorMessage, errorCode];
}
