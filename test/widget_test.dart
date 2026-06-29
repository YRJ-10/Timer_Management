import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timer_management/main.dart';
import 'package:timer_management/providers/sequence_timer_provider.dart';
import 'package:timer_management/providers/session_history_provider.dart';
import 'package:timer_management/providers/settings_provider.dart';
import 'package:timer_management/providers/simple_timer_provider.dart';

void main() {
  testWidgets('shows timer management tabs', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
          ChangeNotifierProvider(create: (_) => SessionHistoryProvider()),
          ChangeNotifierProxyProvider2<
            AppSettingsProvider,
            SessionHistoryProvider,
            SimpleTimerProvider
          >(
            create: (_) => SimpleTimerProvider(),
            update: (_, settings, history, provider) {
              return provider!..attachServices(settings, history);
            },
          ),
          ChangeNotifierProxyProvider2<
            AppSettingsProvider,
            SessionHistoryProvider,
            SequenceTimerProvider
          >(
            create: (_) => SequenceTimerProvider(),
            update: (_, settings, history, provider) {
              return provider!..attachServices(settings, history);
            },
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Timer Management'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Routine'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Routine'));
    await tester.pumpAndSettle();

    expect(find.text('Routine Timer'), findsOneWidget);
  });
}
