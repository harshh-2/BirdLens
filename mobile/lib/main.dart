import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/Welcome/welcome.dart';
import 'package:birdlens/screens/auth/signin.dart';
import 'package:birdlens/screens/auth/signup.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/screens/home/home.dart';
import 'package:birdlens/screens/favorites/favorites.dart';
import 'package:birdlens/screens/birds/bird_screen.dart';
import 'package:birdlens/screens/history/history.dart';
import 'package:birdlens/screens/profile/profile.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:birdlens/screens/splashScreen/splash_screen.dart';
import 'package:birdlens/screens/navigation/navigation.dart';
import 'package:birdlens/screens/auth_gate.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    try {
    await dotenv.load(fileName: ".env");
    debugPrint("ENV LOADED");
  } catch (e) {
    debugPrint("ENV ERROR: $e");
  }

    FlutterError.onError = (details) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      FlutterError.dumpErrorToConsole(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
      return true;
    };
  runApp(
    const ProviderScope(
      child: MyApp(),
      
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

@override
    Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
    return MaterialApp(
      
      debugShowCheckedModeBanner: false,
      initialRoute: "/splash",
      routes: {
        "/splash" :(context)=> SplashScreen(),
        "/auth": (context) => const AuthGate(),
        "/": (context)=>  WelcomeScreen(),
        "/main": (context) => const MainNavigation(),
        "/signIn" : (context)=>const SignIn(),
        "/signUp" : (context)=>const SignUp(),
        "/home" : (context)=>const Home(),
        "/favorites" : (context) => const Favorites(),
        "/history" : (context) => const History(),
        "/profile" : (context) => const Profile(),
        "/birdDetails": (context) {
        final args =ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return BirdScreen(
          bird: args["bird"],
          confidence:
          args["confidence"],
    );
  },
      },
    );
  },
    );
}
}