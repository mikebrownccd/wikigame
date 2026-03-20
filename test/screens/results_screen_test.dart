import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikigame/core/models/question.dart';
import 'package:wikigame/core/models/quiz_session.dart';
import 'package:wikigame/core/services/storage_service.dart';
import 'package:wikigame/providers/progress_provider.dart';
import 'package:wikigame/screens/results_screen.dart';

const _q = Question(
  type: QuestionType.trueFalse,
  question: 'Test?',
  explanation: '',
  isTrue: true,
);

Widget _buildApp(QuizSession session) {
  return MaterialApp(
    home: ChangeNotifierProvider(
      create: (_) => ProgressProvider(StorageService()),
      child: ResultsScreen(session: session),
    ),
  );
}

QuizSession _completeSession({int total = 3, int correct = 0}) {
  var session = QuizSession(
    topic: 'Ancient Rome',
    topicSummary: 'The Roman civilisation.',
    questions: List.generate(total, (_) => _q),
  );
  for (int i = 0; i < total; i++) {
    session = session.answerQuestion(i < correct);
  }
  return session;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows topic name', (tester) async {
    final session = _completeSession(total: 3, correct: 2);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('Ancient Rome'), findsOneWidget);
  });

  testWidgets('shows Quiz Complete when not perfect and not out of lives', (tester) async {
    final session = _completeSession(total: 3, correct: 2);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('Quiz Complete!'), findsOneWidget);
  });

  testWidgets('shows Perfect Score when all correct', (tester) async {
    final session = _completeSession(total: 3, correct: 3);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('Perfect Score!'), findsOneWidget);
  });

  testWidgets('shows Out of Lives when lives reach zero', (tester) async {
    var session = QuizSession(
      topic: 'Test',
      topicSummary: '',
      questions: List.generate(5, (_) => _q),
    );
    // Lose all 3 lives
    session = session.answerQuestion(false);
    session = session.answerQuestion(false);
    session = session.answerQuestion(false);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('Out of Lives'), findsOneWidget);
  });

  testWidgets('shows XP earned badge', (tester) async {
    final session = _completeSession(total: 3, correct: 2);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.textContaining('XP Earned'), findsOneWidget);
  });

  testWidgets('shows correct count in score card', (tester) async {
    final session = _completeSession(total: 3, correct: 2);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('shows accuracy percentage', (tester) async {
    final session = _completeSession(total: 4, correct: 2);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('shows Back to Home button', (tester) async {
    final session = _completeSession(total: 3, correct: 1);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('Back to Home'), findsOneWidget);
  });

  testWidgets('shows Try Another Topic button', (tester) async {
    final session = _completeSession(total: 3, correct: 1);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('Try Another Topic'), findsOneWidget);
  });

  testWidgets('shows trophy icon for perfect score', (tester) async {
    final session = _completeSession(total: 2, correct: 2);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('shows stars icon for partial score', (tester) async {
    final session = _completeSession(total: 3, correct: 2);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    // Icons.stars appears in both the result emoji and the XP badge
    expect(find.byIcon(Icons.stars), findsWidgets);
  });

  testWidgets('zero XP shown when no correct answers', (tester) async {
    final session = _completeSession(total: 3, correct: 0);
    await tester.pumpWidget(_buildApp(session));
    await tester.pump();
    expect(find.text('+0 XP Earned'), findsOneWidget);
  });
}
