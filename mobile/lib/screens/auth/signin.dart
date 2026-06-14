import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:birdlens/widgets/widgets.dart';
import 'package:birdlens/widgets/text_styles.dart';
import 'package:birdlens/widgets/signinwidget.dart' ;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/widgets/app_button.dart';
class SignIn extends StatefulWidget {
  const SignIn({super.key});
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
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
        AppButton(buttonText: "Log In",onTap: (){
          final email = emailController.text.trim();
          final password = passwordController.text;
           if (email.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
          content: Text("Please fill all fields"),
          ),
          );
        return;
        }
      }),
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