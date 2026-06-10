import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/Welcome/welcome.dart';
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

@override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}