import 'package:equatable/equatable.dart';

abstract class OfferListEvent extends Equatable {
  const OfferListEvent();

  @override
  List<Object?> get props => [];
}

class LoadOffers extends OfferListEvent {
  final String taskId;
  const LoadOffers({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

class AcceptOffer extends OfferListEvent {
  final String offerId;
  final String taskId;
  final String paymentMethod;
  
  const AcceptOffer({
    required this.offerId, 
    required this.taskId,
    this.paymentMethod = 'escrow',
  });

  @override
  List<Object?> get props => [offerId, taskId, paymentMethod];
}
