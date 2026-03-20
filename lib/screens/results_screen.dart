import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/quiz_session.dart';
import '../providers/progress_provider.dart';

class ResultsScreen extends StatefulWidget {
  final QuizSession session;

  const ResultsScreen({super.key, required this.session});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().addXp(
            widget.session.xpEarned,
            widget.session.correctCount,
            widget.session.totalQuestions,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isPerfect = session.correctCount == session.totalQuestions;
    final outOfLives = session.lives <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _ResultEmoji(isPerfect: isPerfect, outOfLives: outOfLives),
              const SizedBox(height: 16),
              Text(
                isPerfect
                    ? 'Perfect Score!'
                    : outOfLives
                        ? 'Out of Lives'
                        : 'Quiz Complete!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.topic,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 32),
              _ScoreCard(session: session),
              const SizedBox(height: 24),
              _XpEarnedBadge(xp: session.xpEarned),
              const Spacer(),
              _ActionButtons(onDone: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultEmoji extends StatelessWidget {
  final bool isPerfect;
  final bool outOfLives;

  const _ResultEmoji({required this.isPerfect, required this.outOfLives});

  @override
  Widget build(BuildContext context) {
    if (isPerfect) {
      return const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 72);
    }
    if (outOfLives) {
      return const Icon(Icons.sentiment_dissatisfied,
          color: Color(0xFFFF4B4B), size: 72);
    }
    return const Icon(Icons.stars, color: Color(0xFF58CC02), size: 72);
  }
}

class _ScoreCard extends StatelessWidget {
  final QuizSession session;

  const _ScoreCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final pct = (session.accuracy * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2F38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreStat(
            value: '${session.correctCount}/${session.totalQuestions}',
            label: 'Correct',
            color: const Color(0xFF58CC02),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          _ScoreStat(
            value: '$pct%',
            label: 'Accuracy',
            color: const Color(0xFF1CB0F6),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          _ScoreStat(
            value: '${session.lives}',
            label: 'Lives Left',
            color: const Color(0xFFFF4B4B),
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ScoreStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _XpEarnedBadge extends StatelessWidget {
  final int xp;

  const _XpEarnedBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF58CC02).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF58CC02).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFF58CC02), size: 22),
          const SizedBox(width: 8),
          Text(
            '+$xp XP Earned',
            style: const TextStyle(
              color: Color(0xFF58CC02),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onDone;

  const _ActionButtons({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Try Another Topic',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
