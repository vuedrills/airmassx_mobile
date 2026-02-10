import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/filter_criteria.dart';
import 'filter_event.dart';
import 'filter_state.dart';

/// Filter BLoC - Manages filter criteria for task browsing
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc() : super(const FilterInitial()) {
    on<UpdateFilter>(_onUpdateFilter);
    on<ClearFilters>(_onClearFilters);
    on<ApplyFilters>(_onApplyFilters);
  }

  Future<void> _onUpdateFilter(
    UpdateFilter event,
    Emitter<FilterState> emit,
  ) async {
    emit(FilterUpdated(event.criteria));
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<FilterState> emit,
  ) async {
    const clearedCriteria = FilterCriteria();
    emit(const FilterApplied(clearedCriteria));
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterUpdated) {
      final updatedState = state as FilterUpdated;
      emit(FilterApplied(updatedState.criteria));
    } else if (state is FilterInitial) {
      final initialState = state as FilterInitial;
      emit(FilterApplied(initialState.criteria));
    }
  }
}
