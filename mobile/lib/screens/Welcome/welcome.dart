import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors['background'],
      body: Stack(
      children:[
        Placeholder(),
        Placeholder(),
        Placeholder(),
      ]
      ),
    );
  }
}