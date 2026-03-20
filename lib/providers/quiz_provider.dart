import 'package:flutter/foundation.dart';
import '../core/models/quiz_session.dart';
import '../core/services/wikipedia_service.dart';
import '../core/services/question_generator.dart';

enum QuizState { idle, loading, ready, answering, complete, error }

class QuizProvider extends ChangeNotifier {
  final WikipediaService _wikipedia;
  final QuestionGenerator _generator;

  QuizState _state = QuizState.idle;
  QuizSession? _session;
  String? _errorMessage;
  bool _showingFeedback = false;
  bool? _lastAnswerCorrect;

  QuizProvider({required WikipediaService wikipedia})
      : _wikipedia = wikipedia,
        _generator = QuestionGenerator();

  QuizState get state => _state;
  QuizSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get showingFeedback => _showingFeedback;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;

  Future<void> startQuiz(String topic) async {
    _state = QuizState.loading;
    _errorMessage = null;
    _session = null;
    notifyListeners();

    try {
      final article = await _wikipedia.getArticle(topic);
      final content = await _wikipedia.getFullContent(topic);
      final questions = _generator.generateQuestions(topic, content);

      if (questions.isEmpty) {
        throw Exception('Could not generate questions for this article. Try a different topic.');
      }

      _session = QuizSession(
        topic: article.title,
        topicSummary: article.summary,
        questions: questions,
      );
      _state = QuizState.ready;
    } catch (e) {
      _errorMessage = e.toString();
      _state = QuizState.error;
    }

    notifyListeners();
  }

  void beginAnswering() {
    _state = QuizState.answering;
    notifyListeners();
  }

  void submitAnswer(dynamic answer) {
    if (_session == null || _session!.currentQuestion == null) return;

    final isCorrect = _session!.currentQuestion!.checkAnswer(answer);
    _lastAnswerCorrect = isCorrect;
    _showingFeedback = true;
    _session = _session!.answerQuestion(isCorrect);

    notifyListeners();
  }

  void nextQuestion() {
    _showingFeedback = false;
    _lastAnswerCorrect = null;

    if (_session!.isComplete) {
      _state = QuizState.complete;
    }

    notifyListeners();
  }

  void reset() {
    _state = QuizState.idle;
    _session = null;
    _errorMessage = null;
    _showingFeedback = false;
    _lastAnswerCorrect = null;
    notifyListeners();
  }
}
