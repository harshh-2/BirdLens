import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/Welcome/welcome.dart';
import 'package:birdlens/screens/auth/signin.dart';
import 'package:birdlens/screens/auth/signup.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/screens/home/home.dart';
import 'package:birdlens/screens/favorites/favorites.dart';
import 'package:birdlens/screens/scans/scans.dart';
import 'package:birdlens/screens/history/history.dart';
import 'package:birdlens/screens/profile/profile.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:birdlens/screens/splashScreen/splash_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    const ProviderScope(
      child: MyApp(),
      
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

@override
    Widget build(BuildContext context) {
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
        "/": (context)=> WelcomeScreen() ,
        "/signIn" : (context)=>const SignIn(),
        "/signUp" : (context)=>const SignUp(),
        "/home" : (context)=>const Home(),
        "/favorites" : (context) => const Favorites(),
        "/history" : (context) => const History(),
        "/profile" : (context) => const Profile(),
        "/uploads" : (context) => const Scans(),
      },
    );
  },
    );
}
}