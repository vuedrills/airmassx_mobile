import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import '../../core/error_handler.dart';
import 'offer_event.dart';
import 'offer_state.dart';

class OfferBloc extends Bloc<OfferEvent, OfferState> {
  final ApiService _apiService = getIt<ApiService>();
  
  OfferBloc() : super(const OfferState()) {
    on<OfferAmountChanged>(_onAmountChanged);
    on<OfferMessageChanged>(_onMessageChanged);
    on<OfferAvailabilityChanged>(_onAvailabilityChanged);
    on<OfferInvoiceChanged>(_onInvoiceChanged);
    on<OfferSubmitted>(_onSubmitted);
    on<OfferReset>(_onReset);
  }

  void _onAmountChanged(OfferAmountChanged event, Emitter<OfferState> emit) {
    emit(state.copyWith(
      amount: event.amount,
      status: OfferStatus.initial,
      errorMessage: null,
    ));
  }

  void _onMessageChanged(OfferMessageChanged event, Emitter<OfferState> emit) {
    emit(state.copyWith(
      message: event.message,
      status: OfferStatus.initial,
      errorMessage: null,
    ));
  }

  void _onAvailabilityChanged(OfferAvailabilityChanged event, Emitter<OfferState> emit) {
    emit(state.copyWith(availability: event.availability));
  }

  void _onInvoiceChanged(OfferInvoiceChanged event, Emitter<OfferState> emit) {
    emit(state.copyWith(invoiceFilePath: event.invoiceFilePath));
  }

  void _onReset(OfferReset event, Emitter<OfferState> emit) {
    emit(const OfferState());
  }

  Future<void> _onSubmitted(OfferSubmitted event, Emitter<OfferState> emit) async {
    if (state.amount <= 0) {
      emit(state.copyWith(status: OfferStatus.failure, errorMessage: 'Please enter a valid amount'));
      return;
    }
    // Message is now optional

    emit(state.copyWith(status: OfferStatus.submitting));
    try {
      // Call real API
      await _apiService.createOffer(
        taskId: event.taskId,
        amount: state.amount,
        description: state.message,
        availability: state.availability ?? 'Flexible',
        invoiceFilePath: state.invoiceFilePath,
      );
      emit(state.copyWith(status: OfferStatus.success));
    } catch (e) {
      String message = ErrorHandler.getUserFriendlyMessage(e);
      String? code;
      
      if (e is ApiException) {
        code = e.code;
      }
      
      emit(state.copyWith(
        status: OfferStatus.failure, 
        errorMessage: message,
        errorCode: code,
      ));
    }
  }
}
