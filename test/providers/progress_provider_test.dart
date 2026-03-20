import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikigame/core/services/storage_service.dart';
import 'package:wikigame/providers/progress_provider.dart';

const _progressKey = 'user_progress';

String _progressJson({int xp = 0, int streak = 0}) =>
    '{"xp":$xp,"streak":$streak,"lastPlayedDate":null,"totalQuestionsAnswered":0,"totalCorrect":0}';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('initial state', () {
    test('loaded is false before load()', () {
      final provider = ProgressProvider(StorageService());
      expect(provider.loaded, isFalse);
    });

    test('progress has default values before load()', () {
      final provider = ProgressProvider(StorageService());
      expect(provider.progress.xp, 0);
      expect(provider.progress.streak, 0);
    });
  });

  group('load()', () {
    test('sets loaded to true', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      expect(provider.loaded, isTrue);
    });

    test('loads default progress when nothing stored', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      expect(provider.progress.xp, 0);
      expect(provider.progress.streak, 0);
    });

    test('loads persisted progress', () async {
      SharedPreferences.setMockInitialValues({
        _progressKey: _progressJson(xp: 100, streak: 3),
      });
      final provider = ProgressProvider(StorageService());
      await provider.load();
      expect(provider.progress.xp, 100);
      expect(provider.progress.streak, 3);
    });
  });

  group('addXp()', () {
    test('increases xp', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      await provider.addXp(50, 3, 5);
      expect(provider.progress.xp, 50);
    });

    test('accumulates xp across calls', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      await provider.addXp(30, 2, 5);
      await provider.addXp(20, 1, 5);
      expect(provider.progress.xp, 50);
    });

    test('updates totalQuestionsAnswered', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      await provider.addXp(10, 3, 5);
      expect(provider.progress.totalQuestionsAnswered, 5);
    });

    test('updates totalCorrect', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      await provider.addXp(10, 4, 5);
      expect(provider.progress.totalCorrect, 4);
    });

    test('sets lastPlayedDate to today', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      await provider.addXp(10, 1, 1);
      expect(provider.progress.hasStreakToday, isTrue);
    });

    test('sets streak to 1 on first play', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      await provider.addXp(10, 1, 1);
      expect(provider.progress.streak, 1);
    });

    test('streak stays the same when playing again today', () async {
      final provider = ProgressProvider(StorageService());
      await provider.load();
      await provider.addXp(10, 1, 1); // first play → streak = 1
      await provider.addXp(10, 1, 1); // second play same day → streak unchanged
      expect(provider.progress.streak, 1);
    });

    test('persists progress to storage', () async {
      final storage = StorageService();
      final provider = ProgressProvider(storage);
      await provider.load();
      await provider.addXp(40, 2, 4);

      // Load fresh provider from same storage
      final provider2 = ProgressProvider(storage);
      await provider2.load();
      expect(provider2.progress.xp, 40);
      expect(provider2.progress.totalCorrect, 2);
    });
  });
}
