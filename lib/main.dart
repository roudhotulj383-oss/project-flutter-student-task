import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme_notif.dart';

import 'screens/welcome.dart';
import 'screens/Auth/login.dart';
import 'screens/Auth/register.dart';
import 'screens/dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await ThemeNotifier.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.light,
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.dark,
          ),

          themeMode: mode,

          initialRoute: '/',

          routes: {
            '/': (context) => const WelcomeTo(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/dashboard': (context) => const DashboardPage(),
          },
        );
      },
    );
  }
}