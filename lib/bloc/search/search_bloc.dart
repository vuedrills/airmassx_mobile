import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'search_event.dart';
import 'search_state.dart';

/// Search BLoC - Handles task search, history, and suggestions
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ApiService _apiService;

  SearchBloc(this._apiService) : super(SearchInitial()) {
    on<SearchTasks>(_onSearchTasks);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<ClearSearchHistory>(_onClearSearchHistory);
    on<AddToSearchHistory>(_onAddToSearchHistory);
    on<GetSearchSuggestions>(_onGetSearchSuggestions);
  }

  Future<void> _onSearchTasks(
    SearchTasks event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      final allTasks = await _apiService.getTasks();
      
      // Filter tasks by search query
      final query = event.query.toLowerCase();
      final filteredTasks = allTasks.where((task) {
        return task.title.toLowerCase().contains(query) ||
               task.description.toLowerCase().contains(query) ||
               task.category.toLowerCase().contains(query);
      }).toList();
      
      // Add to search history
      if (event.query.isNotEmpty) {
        await _apiService.addSearchHistory(event.query);
      }
      
      emit(SearchLoaded(tasks: filteredTasks, query: event.query));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final history = await _apiService.getSearchHistory();
      emit(SearchHistoryLoaded(history));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _apiService.clearSearchHistory();
      emit(const SearchHistoryLoaded([]));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onAddToSearchHistory(
    AddToSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _apiService.addSearchHistory(event.query);
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onGetSearchSuggestions(
    GetSearchSuggestions event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final suggestions = await _apiService.getSearchSuggestions(event.query);
      emit(SearchSuggestionsLoaded(suggestions: suggestions, query: event.query));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
