import 'package:flutter_test/flutter_test.dart';
import 'package:wikigame/core/models/question.dart';

void main() {
  group('Question.checkAnswer', () {
    group('multipleChoice', () {
      const q = Question(
        type: QuestionType.multipleChoice,
        question: 'Which is correct?',
        explanation: 'Because C',
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 2,
      );

      test('correct index returns true', () => expect(q.checkAnswer(2), isTrue));
      test('wrong index returns false', () => expect(q.checkAnswer(0), isFalse));
      test('adjacent index returns false', () => expect(q.checkAnswer(3), isFalse));
    });

    group('trueFalse — isTrue: true', () {
      const q = Question(
        type: QuestionType.trueFalse,
        question: 'The Earth orbits the Sun.',
        explanation: 'Yes it does.',
        isTrue: true,
      );

      test('answering true returns true', () => expect(q.checkAnswer(true), isTrue));
      test('answering false returns false', () => expect(q.checkAnswer(false), isFalse));
    });

    group('trueFalse — isTrue: false', () {
      const q = Question(
        type: QuestionType.trueFalse,
        question: 'The Sun orbits the Earth.',
        explanation: 'No.',
        isTrue: false,
      );

      test('answering false returns true', () => expect(q.checkAnswer(false), isTrue));
      test('answering true returns false', () => expect(q.checkAnswer(true), isFalse));
    });

    group('fillBlank', () {
      const q = Question(
        type: QuestionType.fillBlank,
        question: 'The capital of France is ___.',
        explanation: 'Paris is the capital.',
        answer: 'Paris',
      );

      test('exact match', () => expect(q.checkAnswer('Paris'), isTrue));
      test('case insensitive', () => expect(q.checkAnswer('paris'), isTrue));
      test('trimmed whitespace', () => expect(q.checkAnswer('  Paris  '), isTrue));
      test('answer contains user input', () => expect(q.checkAnswer('Par'), isTrue));
      test('wrong answer', () => expect(q.checkAnswer('London'), isFalse));
      test('empty string', () => expect(q.checkAnswer(''), isFalse));
    });
  });

  group('Question.fromJson', () {
    test('parses multiple_choice', () {
      final q = Question.fromJson({
        'type': 'multiple_choice',
        'question': 'Which?',
        'options': ['A', 'B', 'C', 'D'],
        'correct_index': 1,
        'explanation': 'Because B',
      });
      expect(q.type, QuestionType.multipleChoice);
      expect(q.correctIndex, 1);
      expect(q.options, ['A', 'B', 'C', 'D']);
      expect(q.explanation, 'Because B');
    });

    test('parses true_false', () {
      final q = Question.fromJson({
        'type': 'true_false',
        'question': 'True?',
        'is_true': false,
        'explanation': 'No.',
      });
      expect(q.type, QuestionType.trueFalse);
      expect(q.isTrue, false);
    });

    test('parses fill_blank', () {
      final q = Question.fromJson({
        'type': 'fill_blank',
        'question': '___ is a city.',
        'answer': 'Paris',
        'explanation': 'Paris.',
      });
      expect(q.type, QuestionType.fillBlank);
      expect(q.answer, 'Paris');
    });

    test('missing explanation defaults to empty string', () {
      final q = Question.fromJson({
        'type': 'true_false',
        'question': 'Q?',
        'is_true': true,
      });
      expect(q.explanation, '');
    });

    test('unknown type defaults to multipleChoice', () {
      final q = Question.fromJson({
        'type': 'unknown_type',
        'question': 'Q?',
        'explanation': '',
      });
      expect(q.type, QuestionType.multipleChoice);
    });
  });
}
