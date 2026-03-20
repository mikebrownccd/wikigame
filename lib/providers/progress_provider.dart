import 'package:flutter/foundation.dart';
import '../core/models/user_progress.dart';
import '../core/services/storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  final StorageService _storage;

  UserProgress _progress = const UserProgress();
  bool _loaded = false;

  ProgressProvider(this._storage);

  UserProgress get progress => _progress;
  bool get loaded => _loaded;

  Future<void> load() async {
    _progress = await _storage.loadProgress();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addXp(int xp, int correct, int total) async {
    final now = DateTime.now();
    final wasYesterday = _progress.lastPlayedDate != null &&
        _progress.lastPlayedDate!.difference(now).abs().inDays == 1;
    final isToday = _progress.hasStreakToday;

    int newStreak = _progress.streak;
    if (!isToday) {
      newStreak = wasYesterday ? _progress.streak + 1 : 1;
    }

    _progress = _progress.copyWith(
      xp: _progress.xp + xp,
      streak: newStreak,
      lastPlayedDate: now,
      totalQuestionsAnswered: _progress.totalQuestionsAnswered + total,
      totalCorrect: _progress.totalCorrect + correct,
    );

    await _storage.saveProgress(_progress);
    notifyListeners();
  }
}
