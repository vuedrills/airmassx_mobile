import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'question_event.dart';
import 'question_state.dart';

/// Question BLoC - Handles task questions
class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final ApiService _apiService;

  QuestionBloc(this._apiService) : super(QuestionInitial()) {
    on<LoadQuestions>(_onLoadQuestions);
    on<AskQuestion>(_onAskQuestion);
    on<AnswerQuestion>(_onAnswerQuestion);
  }

  Future<void> _onLoadQuestions(
    LoadQuestions event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionsLoading());
    try {
      final questions = await _apiService.getQuestions(event.taskId);
      emit(QuestionsLoaded(questions));
    } catch (e) {
      emit(QuestionError(e.toString()));
    }
  }

  Future<void> _onAskQuestion(
    AskQuestion event,
    Emitter<QuestionState> emit,
  ) async {
    final currentState = state;
    emit(QuestionSending());
    try {
      await _apiService.askQuestion(event.taskId, event.question);
      
      // Reload questions
      final questions = await _apiService.getQuestions(event.taskId);
      emit(QuestionsLoaded(questions));
    } catch (e) {
      // Restore previous state on error
      if (currentState is QuestionsLoaded) {
        emit(currentState);
      }
      emit(QuestionError(e.toString()));
    }
  }

  Future<void> _onAnswerQuestion(
    AnswerQuestion event,
    Emitter<QuestionState> emit,
  ) async {
    final currentState = state;
    emit(QuestionSending());
    try {
      await _apiService.replyToQuestion(event.questionId, event.answer);
      
      // Reload questions to show the new answer
      final questions = await _apiService.getQuestions(event.taskId);
      emit(QuestionsLoaded(questions));
    } catch (e) {
      if (currentState is QuestionsLoaded) {
        emit(currentState);
      }
      emit(QuestionError(e.toString()));
    }
  }
}
