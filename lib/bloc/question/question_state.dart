import 'package:equatable/equatable.dart';
import '../../models/question.dart';

/// Question states
abstract class QuestionState extends Equatable {
  const QuestionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class QuestionInitial extends QuestionState {}

/// Loading questions
class QuestionsLoading extends QuestionState {}

/// Questions loaded
class QuestionsLoaded extends QuestionState {
  final List<Question> questions;

  const QuestionsLoaded(this.questions);

  @override
  List<Object?> get props => [questions];
}

/// Sending question
class QuestionSending extends QuestionState {}

/// Question sent successfully
class QuestionSent extends QuestionState {}

/// Error state
class QuestionError extends QuestionState {
  final String message;

  const QuestionError(this.message);

  @override
  List<Object?> get props => [message];
}
