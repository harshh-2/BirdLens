import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:birdlens/widgets/widgets.dart';
import 'package:birdlens/widgets/text_styles.dart';
import 'package:birdlens/widgets/signinwidget.dart' ;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/widgets/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birdlens/providers/auth_provider.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() =>
      _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
    final authState =ref.watch(authProvider);
    return Container(
     color: colors['background'],
      child:SafeArea(
      child:GestureDetector(
      onTap: () {
      FocusScope.of(context).unfocus();
        },
      child: Scaffold(
      appBar: buildAppbar(),
      backgroundColor: colors['background'],
      body:SingleChildScrollView(
      child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Center(child:Image.asset('assets/images/birdy1.png',fit:BoxFit.fitWidth,height:180.h ,),),
          Center(
            child:Normal16Text(text: "Use your email to log in!"),
          ),
          SizedBox(height: 20.h,),
          appTextfield(controller:emailController,boxtitle:"Email",imgPath:"assets/icons/user.png",hintText: "Enter your Email",isPasswordField: false,keyboardType:TextInputType.emailAddress),
          SizedBox(height: 20.h,),
          appTextfield(controller:passwordController,boxtitle:"Password",imgPath:"assets/icons/password.png",hintText: "Enter your Password",isPasswordField: true,keyboardType:TextInputType.visiblePassword,isPasswordVisible: _isPasswordVisible,onTogglePassword: () {setState(() {_isPasswordVisible = !_isPasswordVisible;});
  },),
  
AppButton(buttonText:
       authState.isLoading
          ? "Logging In..."
          : "Log In",
  onTap: authState.isLoading
      ? null
      : () async {
          final email =emailController.text.trim();
          final password = passwordController.text;
          if (email.isEmpty ||password.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  "Please fill all fields",
                ),
              ),
            );
            return;
          }
          final success = await ref.read(authProvider.notifier,).login(
                    email: email,
                    password:
                        password,
                  );
          if (!mounted) return;
          if (success) {
            Navigator.pushReplacementNamed(context,"/main",);
          } else {
            final error = ref.read(authProvider,).error;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                content: Text(
                  error ??
                      "Login failed",
                ),
              ),
            );
          }
        },
),
        AppButton(buttonText: "SignUp",onTap: (){Navigator.pushReplacementNamed(context, "/signUp");})
        ],
      ),
      ),
     ),
     ),
    ),
    );
    }
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}