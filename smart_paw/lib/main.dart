import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final restoreOutcome = await AuthSession.restore();
  final Widget home = switch (restoreOutcome) {
    AuthRestoreOutcome.validSession => const HomeScreen(),
    AuthRestoreOutcome.clearedExpiredSession => const LoginScreen(),
    AuthRestoreOutcome.noSession => const WelcomeScreen(),
  };
  runApp(MyApp(home: home));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home = const WelcomeScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPaw',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE9A5A1)),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
