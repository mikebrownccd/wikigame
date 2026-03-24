import 'question.dart';

class QuizSession {
  final String topic;
  final String topicSummary;
  final String? imageUrl;
  final String? youtubeSearchQuery;
  final List<Question> questions;
  final List<String> keyFacts;
  final int currentIndex;
  final int lives;
  final int correctCount;
  final List<bool> answers;

  static const int maxLives = 3;
  static const int xpPerCorrect = 10;
  static const int bonusXpAllCorrect = 20;

  const QuizSession({
    required this.topic,
    required this.topicSummary,
    this.imageUrl,
    this.youtubeSearchQuery,
    required this.questions,
    this.keyFacts = const [],
    this.currentIndex = 0,
    this.lives = maxLives,
    this.correctCount = 0,
    this.answers = const [],
  });

  bool get isComplete =>
      currentIndex >= questions.length || lives <= 0;

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get totalQuestions => questions.length;

  int get xpEarned {
    int xp = correctCount * xpPerCorrect;
    if (correctCount == totalQuestions) xp += bonusXpAllCorrect;
    return xp;
  }

  double get accuracy =>
      totalQuestions == 0 ? 0 : correctCount / totalQuestions;

  QuizSession answerQuestion(bool isCorrect) {
    final newAnswers = [...answers, isCorrect];
    return QuizSession(
      topic: topic,
      topicSummary: topicSummary,
      imageUrl: imageUrl,
      youtubeSearchQuery: youtubeSearchQuery,
      questions: questions,
      keyFacts: keyFacts,
      currentIndex: currentIndex + 1,
      lives: isCorrect ? lives : lives - 1,
      correctCount: isCorrect ? correctCount + 1 : correctCount,
      answers: newAnswers,
    );
  }
}
