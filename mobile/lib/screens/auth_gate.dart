import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'navigation/navigation.dart';
import 'package:birdlens/screens/Welcome/welcome.dart';
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final auth =
        ref.watch(authProvider);

    if (auth.user != null) {
      return const MainNavigation();
    }

    return const WelcomeScreen();
  }
}