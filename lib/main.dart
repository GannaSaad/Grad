import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/sign_up_page.dart';
import 'screens/login_page.dart';
import 'screens/welcome_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dentix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
      ),
      home: const WelcomePage(),
    );
  }
}
