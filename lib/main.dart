import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/welcome.dart';
import 'screens/Auth/login.dart';
import 'screens/Auth/register.dart';
import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const WelcomeTo(),

        '/login': (context) => const LoginScreen(),

        '/register': (context) => const RegisterScreen(),

        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}