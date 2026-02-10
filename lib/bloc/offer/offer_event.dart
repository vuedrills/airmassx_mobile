import 'package:equatable/equatable.dart';

abstract class OfferEvent extends Equatable {
  const OfferEvent();

  @override
  List<Object?> get props => [];
}

class OfferAmountChanged extends OfferEvent {
  final double amount;
  const OfferAmountChanged(this.amount);

  @override
  List<Object?> get props => [amount];
}

class OfferMessageChanged extends OfferEvent {
  final String message;
  const OfferMessageChanged(this.message);

  @override
  List<Object?> get props => [message];
}

class OfferSubmitted extends OfferEvent {
  final String taskId;
  const OfferSubmitted(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class OfferAvailabilityChanged extends OfferEvent {
  final String availability;
  const OfferAvailabilityChanged(this.availability);

  @override
  List<Object?> get props => [availability];
}

class OfferInvoiceChanged extends OfferEvent {
  final String? invoiceFilePath;
  const OfferInvoiceChanged(this.invoiceFilePath);

  @override
  List<Object?> get props => [invoiceFilePath];
}

class OfferReset extends OfferEvent {
  const OfferReset();
}
