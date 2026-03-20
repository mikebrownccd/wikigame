import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikigame/screens/settings_screen.dart';

Widget _buildApp() {
  return const MaterialApp(home: SettingsScreen());
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows Settings title', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('shows API key label', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Anthropic API Key'), findsOneWidget);
  });

  testWidgets('shows Save API Key button', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Save API Key'), findsOneWidget);
  });

  testWidgets('shows hint text in text field', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('sk-ant-...'), findsOneWidget);
  });

  testWidgets('text field is obscured by default', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    expect(textFields.any((tf) => tf.obscureText), isTrue);
  });

  testWidgets('visibility toggle button is present', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('tapping visibility toggle reveals text', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });

  testWidgets('can type in the API key field', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'sk-ant-test-key');
    // Text is stored in controller but obscured — verify via controller value
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'sk-ant-test-key');
  });

  testWidgets('Save button updates to Saved! after tap', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.text('Save API Key'));
    await tester.pump(); // process tap
    expect(find.text('Saved!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // drain the 2s reset timer
  });

  testWidgets('loads existing key from storage on init', (tester) async {
    SharedPreferences.setMockInitialValues({
      'anthropic_api_key': 'sk-ant-existing-key',
    });
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    // Key is loaded — field controller has the value (obscured so find by controller)
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'sk-ant-existing-key');
  });
}
