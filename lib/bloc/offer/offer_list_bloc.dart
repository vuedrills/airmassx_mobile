import 'package:flutter_bloc/flutter_bloc.dart';
import 'offer_list_event.dart';
import 'offer_list_state.dart';
import '../../services/api_service.dart';

class OfferListBloc extends Bloc<OfferListEvent, OfferListState> {
  final ApiService _apiService;
  
  OfferListBloc(this._apiService) : super(OfferListInitial()) {
    on<LoadOffers>(_onLoadOffers);
    on<AcceptOffer>(_onAcceptOffer);
  }

  Future<void> _onLoadOffers(LoadOffers event, Emitter<OfferListState> emit) async {
    emit(OfferListLoading());
    try {
      final offers = await _apiService.getOffersForTask(event.taskId);
      emit(OfferListLoaded(offers: offers));
    } catch (e) {
      emit(OfferListFailure(message: e.toString()));
    }
  }

  Future<void> _onAcceptOffer(AcceptOffer event, Emitter<OfferListState> emit) async {
    final currentState = state;
    if (currentState is! OfferListLoaded) return;

    emit(OfferListLoading());
    try {
      print('OfferListBloc: Accepting offer ${event.offerId} with method ${event.paymentMethod}');
      await _apiService.acceptOffer(
        event.offerId, 
        event.taskId, 
        paymentMethod: event.paymentMethod,
      );
      
      // Reload offers to show updated state
      final offers = await _apiService.getOffersForTask(event.taskId);
      emit(OfferListLoaded(offers: offers, message: 'Offer accepted successfully!'));
    } catch (e) {
      print('OfferListBloc: Error accepting offer: $e');
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.userFriendlyMessage;
      } else {
        errorMessage = 'Something went wrong. Please try again.';
      }
      emit(OfferListFailure(message: errorMessage));
    }
  }
}
