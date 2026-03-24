import 'package:flutter_test/flutter_test.dart';
import 'package:wikigame/core/models/question.dart';
import 'package:wikigame/core/services/question_generator.dart';

const _richContent = '''
The Eiffel Tower is a wrought-iron lattice tower on the Champ de Mars in Paris, France.
It is named after the engineer Gustave Eiffel, whose company designed and built the tower.
Construction began in 1887 and was completed in 1889 as the entrance arch for the 1889 World Fair.
The tower stands 330 metres tall and is the tallest structure in Paris.
Gustave Eiffel initially received criticism from prominent French artists and intellectuals.
Today it attracts approximately 7 million visitors per year, making it the most visited paid monument in the world.
The tower has three levels for visitors, with restaurants on the first and second levels.
The top floor observatory offers stunning views extending 70 kilometres on a clear day.
Construction required 18038 pieces of wrought iron and 2500000 rivets to assemble.
''';

const _shortContent = 'Brief text.';

void main() {
  late QuestionGenerator generator;

  setUp(() => generator = QuestionGenerator());

  group('extractKeyFacts', () {
    test('returns up to 3 facts for rich content', () {
      final facts = generator.extractKeyFacts(_richContent);
      expect(facts.length, greaterThan(0));
      expect(facts.length, lessThanOrEqualTo(3));
    });

    test('returns empty list for empty content', () {
      expect(generator.extractKeyFacts(''), isEmpty);
    });

    test('returns empty list for very short content', () {
      expect(generator.extractKeyFacts(_shortContent), isEmpty);
    });

    test('all facts are non-empty strings', () {
      for (final fact in generator.extractKeyFacts(_richContent)) {
        expect(fact.trim(), isNotEmpty);
      }
    });

    test('prioritises sentences containing years', () {
      final facts = generator.extractKeyFacts(_richContent);
      final hasYear = facts.any((f) => RegExp(r'\b\d{4}\b').hasMatch(f));
      expect(hasYear, isTrue);
    });

    test('facts are reasonable length (not too short)', () {
      for (final fact in generator.extractKeyFacts(_richContent)) {
        expect(fact.length, greaterThan(20));
      }
    });
  });

  group('generateQuestions', () {
    test('returns 5 questions for rich content', () {
      expect(generator.generateQuestions('Eiffel Tower', _richContent).length, 5);
    });

    test('returns empty list for empty content', () {
      expect(generator.generateQuestions('Test', ''), isEmpty);
    });

    test('includes at least one multiple choice question', () {
      final qs = generator.generateQuestions('Eiffel Tower', _richContent);
      expect(qs.any((q) => q.type == QuestionType.multipleChoice), isTrue);
    });

    test('includes at least one true/false question', () {
      final qs = generator.generateQuestions('Eiffel Tower', _richContent);
      expect(qs.any((q) => q.type == QuestionType.trueFalse), isTrue);
    });

    test('all questions have non-empty question text', () {
      for (final q in generator.generateQuestions('Eiffel Tower', _richContent)) {
        expect(q.question.trim(), isNotEmpty);
      }
    });

    test('all questions have non-empty explanation', () {
      for (final q in generator.generateQuestions('Eiffel Tower', _richContent)) {
        expect(q.explanation.trim(), isNotEmpty);
      }
    });

    group('multiple choice questions', () {
      late List<Question> mcQuestions;

      setUp(() {
        mcQuestions = generator
            .generateQuestions('Eiffel Tower', _richContent)
            .where((q) => q.type == QuestionType.multipleChoice)
            .toList();
      });

      test('have exactly 4 options', () {
        for (final q in mcQuestions) {
          expect(q.options?.length, 4);
        }
      });

      test('have a valid correctIndex', () {
        for (final q in mcQuestions) {
          expect(q.correctIndex, isNotNull);
          expect(q.correctIndex, inInclusiveRange(0, 3));
        }
      });

      test('correct answer is one of the options', () {
        for (final q in mcQuestions) {
          expect(q.options![q.correctIndex!], isNotEmpty);
        }
      });

      test('all options are distinct', () {
        for (final q in mcQuestions) {
          expect(q.options!.toSet().length, q.options!.length);
        }
      });

      test('checkAnswer returns true for correct index', () {
        for (final q in mcQuestions) {
          expect(q.checkAnswer(q.correctIndex), isTrue);
        }
      });
    });

    group('true/false questions', () {
      late List<Question> tfQuestions;

      setUp(() {
        tfQuestions = generator
            .generateQuestions('Eiffel Tower', _richContent)
            .where((q) => q.type == QuestionType.trueFalse)
            .toList();
      });

      test('have isTrue set', () {
        for (final q in tfQuestions) {
          expect(q.isTrue, isNotNull);
        }
      });

      test('checkAnswer returns true for correct bool', () {
        for (final q in tfQuestions) {
          expect(q.checkAnswer(q.isTrue), isTrue);
        }
      });

      test('checkAnswer returns false for wrong bool', () {
        for (final q in tfQuestions) {
          expect(q.checkAnswer(!q.isTrue!), isFalse);
        }
      });
    });

    group('fill-in-the-blank questions', () {
      late List<Question> fillQuestions;

      setUp(() {
        fillQuestions = generator
            .generateQuestions('Eiffel Tower', _richContent)
            .where((q) => q.type == QuestionType.fillBlank)
            .toList();
      });

      test('have a non-empty answer', () {
        for (final q in fillQuestions) {
          expect(q.answer, isNotNull);
          expect(q.answer!.trim(), isNotEmpty);
        }
      });

      test('question text contains blank marker ___', () {
        for (final q in fillQuestions) {
          expect(q.question, contains('___'));
        }
      });

      test('checkAnswer returns true for correct answer', () {
        for (final q in fillQuestions) {
          expect(q.checkAnswer(q.answer!), isTrue);
        }
      });
    });
  });
}
