import 'package:equatable/equatable.dart';

/// Question events
abstract class QuestionEvent extends Equatable {
  const QuestionEvent();

  @override
  List<Object?> get props => [];
}

/// Load questions for a task
class LoadQuestions extends QuestionEvent {
  final String taskId;

  const LoadQuestions(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Ask a new question
class AskQuestion extends QuestionEvent {
  final String taskId;
  final String question;

  const AskQuestion({
    required this.taskId,
    required this.question,
  });

  @override
  List<Object?> get props => [taskId, question];
}

/// Answer an existing question (Poster only)
class AnswerQuestion extends QuestionEvent {
  final String taskId;
  final String questionId;
  final String answer;

  const AnswerQuestion({
    required this.taskId,
    required this.questionId,
    required this.answer,
  });

  @override
  List<Object?> get props => [taskId, questionId, answer];
}
