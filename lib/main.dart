import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'providers/session_history_provider.dart';
import 'providers/sequence_timer_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/simple_timer_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => SessionHistoryProvider()),
        ChangeNotifierProxyProvider2<
            AppSettingsProvider,
            SessionHistoryProvider,
            SimpleTimerProvider>(
          create: (_) => SimpleTimerProvider(),
          update: (_, settings, history, provider) {
            return provider!..attachServices(settings, history);
          },
        ),
        ChangeNotifierProxyProvider2<
            AppSettingsProvider,
            SessionHistoryProvider,
            SequenceTimerProvider>(
          create: (_) => SequenceTimerProvider(),
          update: (_, settings, history, provider) {
            return provider!..attachServices(settings, history);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timer Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        fontFamily: 'Inter', // We can use google fonts or default.
      ),
      home: const HomeScreen(),
    );
  }
}
