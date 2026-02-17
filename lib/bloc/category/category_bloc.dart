import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../core/error_handler.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiService _apiService;

  CategoryBloc(this._apiService) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    if (state is CategoryLoaded && !event.forceRefresh) return;

    emit(CategoryLoading());
    try {
      final categories = await _apiService.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(ErrorHandler.getUserFriendlyMessage(e)));
    }
  }
}
