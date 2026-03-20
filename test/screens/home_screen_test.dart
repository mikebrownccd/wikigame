import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikigame/core/services/storage_service.dart';
import 'package:wikigame/providers/progress_provider.dart';
import 'package:wikigame/screens/home_screen.dart';

Future<Widget> _buildLoadedApp() async {
  final provider = ProgressProvider(StorageService());
  await provider.load();
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: provider,
      child: const HomeScreen(),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows app title', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    expect(find.text('WikiGame'), findsOneWidget);
  });

  testWidgets('shows Start Learning button', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    expect(find.text('Start Learning'), findsOneWidget);
  });

  testWidgets('shows Level label', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    expect(find.textContaining('Level'), findsWidgets);
  });

  testWidgets('shows settings icon button', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('shows streak chip with fire icon', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
  });

  testWidgets('shows XP chip', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    expect(find.text('XP'), findsOneWidget);
  });

  testWidgets('shows Your Stats section', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    expect(find.text('Your Stats'), findsOneWidget);
  });

  testWidgets('tapping Start Learning navigates to search screen', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    await tester.tap(find.text('Start Learning'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a Topic'), findsOneWidget);
  });

  testWidgets('tapping settings navigates to settings screen', (tester) async {
    await tester.pumpWidget(await _buildLoadedApp());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
