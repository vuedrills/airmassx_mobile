import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import '../../core/error_handler.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiService _apiService = getIt<ApiService>();

  InventoryBloc() : super(InventoryInitial()) {
    on<LoadInventory>((event, emit) async {
      emit(InventoryLoading());
      try {
        final items = await _apiService.getMyInventory();
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(ErrorHandler.getUserFriendlyMessage(e)));
      }
    });

    on<AddInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      try {
        await _apiService.createInventoryItem(event.data);
        final items = await _apiService.getMyInventory();
        emit(InventoryOperationSuccess('Item added successfully'));
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(ErrorHandler.getUserFriendlyMessage(e)));
      }
    });

    on<UpdateInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      try {
        await _apiService.updateInventoryItem(event.id, event.data);
        final items = await _apiService.getMyInventory();
        emit(InventoryOperationSuccess('Item updated successfully'));
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(ErrorHandler.getUserFriendlyMessage(e)));
      }
    });

    on<DeleteInventoryItem>((event, emit) async {
      emit(InventoryLoading());
      try {
        await _apiService.deleteInventoryItem(event.id);
        final items = await _apiService.getMyInventory();
        emit(InventoryOperationSuccess('Item deleted successfully'));
        emit(InventoryLoaded(items));
      } catch (e) {
        emit(InventoryError(ErrorHandler.getUserFriendlyMessage(e)));
      }
    });
  }
}
