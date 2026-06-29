import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timer_management/main.dart';
import 'package:timer_management/providers/sequence_timer_provider.dart';
import 'package:timer_management/providers/simple_timer_provider.dart';

void main() {
  testWidgets('shows timer screens', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SimpleTimerProvider()),
          ChangeNotifierProvider(create: (_) => SequenceTimerProvider()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Simple'), findsOneWidget);
    expect(find.text('Sequence'), findsOneWidget);

    await tester.tap(find.text('Sequence'));
    await tester.pumpAndSettle();

    expect(find.text('Sequence Timer'), findsOneWidget);
  });
}
