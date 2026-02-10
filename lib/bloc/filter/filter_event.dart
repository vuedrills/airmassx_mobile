import 'package:equatable/equatable.dart';
import '../../models/filter_criteria.dart';

/// Filter events
abstract class FilterEvent extends Equatable {
  const FilterEvent();

  @override
  List<Object?> get props => [];
}

/// Update filter criteria
class UpdateFilter extends FilterEvent {
  final FilterCriteria criteria;

  const UpdateFilter(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

/// Clear all filters
class ClearFilters extends FilterEvent {}

/// Apply filters to tasks
class ApplyFilters extends FilterEvent {}
