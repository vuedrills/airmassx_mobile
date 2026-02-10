import 'package:equatable/equatable.dart';
import '../../models/filter_criteria.dart';

/// Filter states
abstract class FilterState extends Equatable {
  const FilterState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FilterInitial extends FilterState {
  final FilterCriteria criteria;

  const FilterInitial({this.criteria = const FilterCriteria()});

  @override
  List<Object?> get props => [criteria];
}

/// Filter updated (not yet applied)
class FilterUpdated extends FilterState {
  final FilterCriteria criteria;

  const FilterUpdated(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

/// Filters applied
class FilterApplied extends FilterState {
  final FilterCriteria criteria;

  const FilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}
