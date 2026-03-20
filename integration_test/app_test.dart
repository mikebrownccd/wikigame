import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikigame/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('App launch', () {
    testWidgets('home screen loads with WikiGame title', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.text('WikiGame'), findsOneWidget);
    });

    testWidgets('Start Learning button is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.text('Start Learning'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('tapping Start Learning opens search screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Learning'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a Topic'), findsOneWidget);
    });

    testWidgets('search screen shows Popular Topics', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Learning'));
      await tester.pumpAndSettle();
      expect(find.text('Popular Topics'), findsOneWidget);
    });

    testWidgets('search screen shows suggested topic cards', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Learning'));
      await tester.pumpAndSettle();
      expect(find.text('Solar System'), findsOneWidget);
    });

    testWidgets('back button from search returns to home', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Learning'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('WikiGame'), findsOneWidget);
    });

    testWidgets('settings screen opens from home', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('settings screen shows API key field', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Anthropic API Key'), findsOneWidget);
    });
  });

  group('Search functionality', () {
    testWidgets('search field is present and accepts input', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Learning'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Rome');
      expect(find.text('Rome'), findsOneWidget);
    });
  });
}
