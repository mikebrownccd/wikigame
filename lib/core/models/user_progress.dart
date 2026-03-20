class UserProgress {
  final int xp;
  final int streak;
  final DateTime? lastPlayedDate;
  final int totalQuestionsAnswered;
  final int totalCorrect;

  const UserProgress({
    this.xp = 0,
    this.streak = 0,
    this.lastPlayedDate,
    this.totalQuestionsAnswered = 0,
    this.totalCorrect = 0,
  });

  int get level => (xp / 100).floor() + 1;
  int get xpInCurrentLevel => xp % 100;
  double get levelProgress => xpInCurrentLevel / 100.0;
  double get accuracy => totalQuestionsAnswered == 0
      ? 0
      : totalCorrect / totalQuestionsAnswered;

  bool get hasStreakToday {
    if (lastPlayedDate == null) return false;
    final now = DateTime.now();
    final last = lastPlayedDate!;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  UserProgress copyWith({
    int? xp,
    int? streak,
    DateTime? lastPlayedDate,
    int? totalQuestionsAnswered,
    int? totalCorrect,
  }) {
    return UserProgress(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrect: totalCorrect ?? this.totalCorrect,
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streak': streak,
        'lastPlayedDate': lastPlayedDate?.toIso8601String(),
        'totalQuestionsAnswered': totalQuestionsAnswered,
        'totalCorrect': totalCorrect,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      xp: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastPlayedDate: json['lastPlayedDate'] != null
          ? DateTime.parse(json['lastPlayedDate'] as String)
          : null,
      totalQuestionsAnswered: json['totalQuestionsAnswered'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
    );
  }
}
