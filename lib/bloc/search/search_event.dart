import 'package:equatable/equatable.dart';

/// Search events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Search for tasks
class SearchTasks extends SearchEvent {
  final String query;

  const SearchTasks(this.query);

  @override
  List<Object?> get props => [query];
}

/// Load search history
class LoadSearchHistory extends SearchEvent {}

/// Clear search history
class ClearSearchHistory extends SearchEvent {}

/// Add query to search history
class AddToSearchHistory extends SearchEvent {
  final String query;

  const AddToSearchHistory(this.query);

  @override
  List<Object?> get props => [query];
}

/// Get search suggestions
class GetSearchSuggestions extends SearchEvent {
  final String query;

  const GetSearchSuggestions(this.query);

  @override
  List<Object?> get props => [query];
}
