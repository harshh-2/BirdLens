import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:birdlens/widgets/widgets.dart';
import 'package:birdlens/widgets/text_styles.dart';
import 'package:birdlens/widgets/signupwidget.dart' ;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/widgets/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birdlens/providers/auth_provider.dart';
class SignUp extends ConsumerStatefulWidget {
  const SignUp({super.key});

  @override
  ConsumerState<SignUp> createState() =>
      _SignUpState();
}
class _SignUpState extends ConsumerState<SignUp> {
  final usernameController = TextEditingController();
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
          Center(child:Image.asset('assets/images/Parrot.png',fit:BoxFit.fitWidth,height:180.h ,),),
          Center(
            child:Normal16Text(text: "Use your email to sign up!"),
          ),
          appTextfield(controller:usernameController,boxtitle:"Username",imgPath:"assets/icons/username.png",hintText: "Create your username",isPasswordField: false,keyboardType:TextInputType.name),
          SizedBox(height: 10.h,),
          appTextfield(controller:emailController,boxtitle:"Email",imgPath:"assets/icons/user.png",hintText: "Enter your Email",isPasswordField: false,keyboardType:TextInputType.emailAddress),
          SizedBox(height: 10.h,),
          appTextfield(controller:passwordController ,boxtitle:"Password",imgPath:"assets/icons/password.png",hintText: "Create your Password",isPasswordField: true,keyboardType:TextInputType.visiblePassword,isPasswordVisible: _isPasswordVisible,onTogglePassword: () {setState(() {_isPasswordVisible = !_isPasswordVisible;});},),
          AppButton(
          buttonText: authState.isLoading? "Registering..." : "Sign Up",
          onTap: authState.isLoading ? null: () async {
          final username = usernameController.text.trim();
          final email = emailController.text.trim();
          final password = passwordController.text;
          if (username.isEmpty || email.isEmpty || password.isEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Please fill all fields",
                ),
              ),
            );
            return;
          }
          final success = await ref.read(authProvider.notifier,).signup(
                    username: username,
                    email: email,
                    password: password,
                  );
          if (!mounted) return;
          if (success) {
            Navigator.pushReplacementNamed(context,"/main",);
          } else {
            final error =
                ref.read(authProvider).error;
            ScaffoldMessenger.of(context)
                .showSnackBar(
              SnackBar(
                content: Text(
                  error ??
                      "Signup failed",
                ),
              ),
            );
          }
        },
),
          AppButton(buttonText: "Sign in Instead?",onTap: (){Navigator.pushReplacementNamed(context,"/signIn",);})
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
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}