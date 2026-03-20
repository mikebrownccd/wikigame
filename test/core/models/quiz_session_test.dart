import 'package:flutter_test/flutter_test.dart';
import 'package:wikigame/core/models/question.dart';
import 'package:wikigame/core/models/quiz_session.dart';

const _q = Question(
  type: QuestionType.trueFalse,
  question: 'Test?',
  explanation: '',
  isTrue: true,
);

QuizSession _session({int count = 5}) => QuizSession(
      topic: 'Test Topic',
      topicSummary: 'A summary.',
      questions: List.generate(count, (_) => _q),
    );

void main() {
  group('initial state', () {
    final s = _session();
    test('currentIndex is 0', () => expect(s.currentIndex, 0));
    test('lives is 3', () => expect(s.lives, QuizSession.maxLives));
    test('correctCount is 0', () => expect(s.correctCount, 0));
    test('not complete', () => expect(s.isComplete, isFalse));
    test('currentQuestion is first question', () => expect(s.currentQuestion, _q));
    test('totalQuestions is 5', () => expect(s.totalQuestions, 5));
    test('xpEarned is 0', () => expect(s.xpEarned, 0));
    test('accuracy is 0', () => expect(s.accuracy, 0));
  });

  group('answerQuestion — correct', () {
    final next = _session().answerQuestion(true);
    test('increments currentIndex', () => expect(next.currentIndex, 1));
    test('increments correctCount', () => expect(next.correctCount, 1));
    test('does not decrement lives', () => expect(next.lives, 3));
  });

  group('answerQuestion — wrong', () {
    final next = _session().answerQuestion(false);
    test('increments currentIndex', () => expect(next.currentIndex, 1));
    test('decrements lives', () => expect(next.lives, 2));
    test('does not increment correctCount', () => expect(next.correctCount, 0));
  });

  group('isComplete', () {
    test('completes when all questions answered', () {
      var s = _session(count: 3);
      s = s.answerQuestion(true);
      s = s.answerQuestion(true);
      s = s.answerQuestion(true);
      expect(s.isComplete, isTrue);
    });

    test('completes when out of lives', () {
      var s = _session();
      s = s.answerQuestion(false);
      s = s.answerQuestion(false);
      s = s.answerQuestion(false);
      expect(s.lives, 0);
      expect(s.isComplete, isTrue);
    });

    test('not complete mid-quiz', () {
      final s = _session().answerQuestion(true);
      expect(s.isComplete, isFalse);
    });
  });

  group('currentQuestion', () {
    test('advances with each answer', () {
      final questions = [
        const Question(type: QuestionType.trueFalse, question: 'Q1?', explanation: '', isTrue: true),
        const Question(type: QuestionType.trueFalse, question: 'Q2?', explanation: '', isTrue: false),
      ];
      var s = QuizSession(topic: 'T', topicSummary: '', questions: questions);
      expect(s.currentQuestion, questions[0]);
      s = s.answerQuestion(true);
      expect(s.currentQuestion, questions[1]);
    });

    test('is null when complete', () {
      var s = _session(count: 1);
      s = s.answerQuestion(true);
      expect(s.currentQuestion, isNull);
    });
  });

  group('xpEarned', () {
    test('2 correct = 2 * xpPerCorrect', () {
      var s = _session();
      s = s.answerQuestion(true);
      s = s.answerQuestion(true);
      expect(s.xpEarned, 2 * QuizSession.xpPerCorrect);
    });

    test('all correct adds bonus XP', () {
      var s = _session(count: 3);
      for (int i = 0; i < 3; i++) s = s.answerQuestion(true);
      expect(s.xpEarned, 3 * QuizSession.xpPerCorrect + QuizSession.bonusXpAllCorrect);
    });

    test('wrong answers earn no XP', () {
      var s = _session();
      s = s.answerQuestion(false);
      expect(s.xpEarned, 0);
    });
  });

  group('accuracy', () {
    test('empty session gives 0', () {
      final s = QuizSession(topic: 'T', topicSummary: '', questions: []);
      expect(s.accuracy, 0);
    });

    test('all correct = 1.0', () {
      var s = _session(count: 4);
      for (int i = 0; i < 4; i++) s = s.answerQuestion(true);
      expect(s.accuracy, 1.0);
    });

    test('half correct = 0.5', () {
      var s = _session(count: 4);
      s = s.answerQuestion(true);
      s = s.answerQuestion(true);
      s = s.answerQuestion(false);
      s = s.answerQuestion(false);
      expect(s.accuracy, closeTo(0.5, 0.001));
    });
  });

  group('keyFacts preserved through answerQuestion', () {
    test('keyFacts are carried through', () {
      final s = QuizSession(
        topic: 'T',
        topicSummary: '',
        questions: [_q],
        keyFacts: ['Fact A', 'Fact B'],
      );
      final next = s.answerQuestion(true);
      expect(next.keyFacts, ['Fact A', 'Fact B']);
    });
  });

  group('immutability', () {
    test('original session unchanged after answerQuestion', () {
      final original = _session();
      original.answerQuestion(true);
      expect(original.currentIndex, 0);
      expect(original.correctCount, 0);
    });
  });
}
