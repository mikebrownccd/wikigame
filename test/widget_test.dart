import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikigame/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const WikiGameApp());
    await tester.pump();
    expect(find.text('WikiGame'), findsOneWidget);
  });
}
