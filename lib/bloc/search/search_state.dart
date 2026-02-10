import 'package:equatable/equatable.dart';
import '../../models/task.dart';
import '../../models/search_history.dart';

/// Search states
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SearchInitial extends SearchState {}

/// Loading search results
class SearchLoading extends SearchState {}

/// Search results loaded
class SearchLoaded extends SearchState {
  final List<Task> tasks;
  final String query;

  const SearchLoaded({
    required this.tasks,
    required this.query,
  });

  @override
  List<Object?> get props => [tasks, query];
}

/// Search history loaded
class SearchHistoryLoaded extends SearchState {
  final List<SearchHistory> history;

  const SearchHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

/// Search suggestions loaded
class SearchSuggestionsLoaded extends SearchState {
  final List<String> suggestions;
  final String query;

  const SearchSuggestionsLoaded({
    required this.suggestions,
    required this.query,
  });

  @override
  List<Object?> get props => [suggestions, query];
}

/// Error state
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
