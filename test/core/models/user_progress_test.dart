import 'package:flutter_test/flutter_test.dart';
import 'package:wikigame/core/models/user_progress.dart';

void main() {
  group('defaults', () {
    const p = UserProgress();
    test('xp is 0', () => expect(p.xp, 0));
    test('streak is 0', () => expect(p.streak, 0));
    test('level is 1', () => expect(p.level, 1));
    test('accuracy is 0', () => expect(p.accuracy, 0));
    test('lastPlayedDate is null', () => expect(p.lastPlayedDate, isNull));
    test('hasStreakToday is false', () => expect(p.hasStreakToday, isFalse));
  });

  group('level', () {
    test('level 1 at 0 xp', () => expect(const UserProgress(xp: 0).level, 1));
    test('level 1 at 99 xp', () => expect(const UserProgress(xp: 99).level, 1));
    test('level 2 at 100 xp', () => expect(const UserProgress(xp: 100).level, 2));
    test('level 2 at 199 xp', () => expect(const UserProgress(xp: 199).level, 2));
    test('level 3 at 200 xp', () => expect(const UserProgress(xp: 200).level, 3));
    test('level 11 at 1000 xp', () => expect(const UserProgress(xp: 1000).level, 11));
  });

  group('xpInCurrentLevel', () {
    test('0 xp = 0 in level', () => expect(const UserProgress(xp: 0).xpInCurrentLevel, 0));
    test('50 xp = 50 in level', () => expect(const UserProgress(xp: 50).xpInCurrentLevel, 50));
    test('100 xp = 0 in next level', () => expect(const UserProgress(xp: 100).xpInCurrentLevel, 0));
    test('150 xp = 50 in level 2', () => expect(const UserProgress(xp: 150).xpInCurrentLevel, 50));
  });

  group('levelProgress', () {
    test('0 xp = 0.0 progress', () => expect(const UserProgress(xp: 0).levelProgress, 0.0));
    test('50 xp = 0.5 progress', () => expect(const UserProgress(xp: 50).levelProgress, closeTo(0.5, 0.001)));
    test('75 xp = 0.75 progress', () => expect(const UserProgress(xp: 75).levelProgress, closeTo(0.75, 0.001)));
    test('100 xp = 0.0 (new level)', () => expect(const UserProgress(xp: 100).levelProgress, 0.0));
  });

  group('accuracy', () {
    test('no questions = 0', () => expect(const UserProgress().accuracy, 0));
    test('10/10 = 1.0', () {
      const p = UserProgress(totalQuestionsAnswered: 10, totalCorrect: 10);
      expect(p.accuracy, 1.0);
    });
    test('5/10 = 0.5', () {
      const p = UserProgress(totalQuestionsAnswered: 10, totalCorrect: 5);
      expect(p.accuracy, 0.5);
    });
    test('1/4 = 0.25', () {
      const p = UserProgress(totalQuestionsAnswered: 4, totalCorrect: 1);
      expect(p.accuracy, closeTo(0.25, 0.001));
    });
  });

  group('hasStreakToday', () {
    test('null lastPlayedDate = false', () {
      expect(const UserProgress().hasStreakToday, isFalse);
    });

    test('lastPlayedDate today = true', () {
      final now = DateTime.now();
      final p = UserProgress(lastPlayedDate: DateTime(now.year, now.month, now.day, 9, 0));
      expect(p.hasStreakToday, isTrue);
    });

    test('lastPlayedDate yesterday = false', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final p = UserProgress(lastPlayedDate: yesterday);
      expect(p.hasStreakToday, isFalse);
    });
  });

  group('copyWith', () {
    const original = UserProgress(xp: 50, streak: 3, totalQuestionsAnswered: 10, totalCorrect: 7);

    test('updates xp only', () {
      final updated = original.copyWith(xp: 100);
      expect(updated.xp, 100);
      expect(updated.streak, 3); // unchanged
      expect(updated.totalCorrect, 7); // unchanged
    });

    test('updates streak only', () {
      final updated = original.copyWith(streak: 5);
      expect(updated.streak, 5);
      expect(updated.xp, 50); // unchanged
    });

    test('no changes returns equivalent object', () {
      final copy = original.copyWith();
      expect(copy.xp, original.xp);
      expect(copy.streak, original.streak);
      expect(copy.totalQuestionsAnswered, original.totalQuestionsAnswered);
      expect(copy.totalCorrect, original.totalCorrect);
    });
  });

  group('JSON serialization', () {
    test('toJson includes all fields', () {
      const p = UserProgress(xp: 150, streak: 3, totalQuestionsAnswered: 20, totalCorrect: 15);
      final json = p.toJson();
      expect(json['xp'], 150);
      expect(json['streak'], 3);
      expect(json['totalQuestionsAnswered'], 20);
      expect(json['totalCorrect'], 15);
    });

    test('fromJson round-trip preserves values', () {
      const original = UserProgress(xp: 250, streak: 7, totalQuestionsAnswered: 30, totalCorrect: 22);
      final restored = UserProgress.fromJson(original.toJson());
      expect(restored.xp, original.xp);
      expect(restored.streak, original.streak);
      expect(restored.totalQuestionsAnswered, original.totalQuestionsAnswered);
      expect(restored.totalCorrect, original.totalCorrect);
    });

    test('fromJson with lastPlayedDate round-trips', () {
      final date = DateTime(2025, 6, 15);
      final p = UserProgress(lastPlayedDate: date);
      final restored = UserProgress.fromJson(p.toJson());
      expect(restored.lastPlayedDate?.year, 2025);
      expect(restored.lastPlayedDate?.month, 6);
      expect(restored.lastPlayedDate?.day, 15);
    });

    test('fromJson with null lastPlayedDate', () {
      final json = {'xp': 0, 'streak': 0, 'lastPlayedDate': null, 'totalQuestionsAnswered': 0, 'totalCorrect': 0};
      final p = UserProgress.fromJson(json);
      expect(p.lastPlayedDate, isNull);
    });

    test('fromJson with missing fields uses defaults', () {
      final p = UserProgress.fromJson({});
      expect(p.xp, 0);
      expect(p.streak, 0);
    });
  });
}
