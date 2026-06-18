import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/providers/auth_provider.dart';
import 'package:birdlens/themes/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    try {
      await ref
          .read(
            authProvider.notifier,
          )
          .checkAuth();
    } catch (e, st) {
      debugPrint('Splash _checkAuth error: $e');
      debugPrint('$st');
    } finally {
      if (!mounted) return;
      // Always navigate to the auth gate so the app can decide next screen.
      Navigator.pushReplacementNamed(
        context,
        "/auth",
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          colors['background'],
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 180.h,
            ),
            SizedBox(height: 25.h),
            Text(
              "BirdLens",
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight:
                    FontWeight.bold,
                color:
                    colors['primary'],
              ),
            ),
            SizedBox(height: 15.h),
            CircularProgressIndicator(
              color:
                  colors['primary'],
            ),
          ],
        ),
      ),
    );
  }
}