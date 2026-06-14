import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/Welcome/welcome.dart';
import 'package:birdlens/screens/auth/signin.dart';
import 'package:birdlens/screens/auth/signup.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
void main() {
  runApp(const ProviderScope(child: MyApp()));
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
      initialRoute: "/",
      routes: {
        "/":(context)=> WelcomeScreen() ,
        "/signIn" :(context)=>const SignIn(),
        "/signUp" :(context)=>const SignUp(),
      },
    );
  },
    );
}
}