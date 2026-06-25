import 'package:flutter/material.dart';
import 'package:birdlens/widgets/text_styles.dart';
import 'package:birdlens/widgets/app_shadows.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
Widget WelcomePage({required String imgpath,required String title, required String description,required String buttonText, required VoidCallback onTap}){        
  return Column(
              children: [
              Image.asset(imgpath,fit:BoxFit.fitWidth),
              Container(
                margin: EdgeInsets.only(top: 15),
                child: BoldText(text:title),
                ),
              Container(
                margin: EdgeInsets.only(top: 15),
                padding: EdgeInsets.only(left:30,right:30),
                child: Normal16Text(text:description),
                ),
                _Button(buttonText:buttonText,onTap:onTap)
              ],
            );
}

Widget _Button({
  required String buttonText,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 325.w,
      height: 50.h,
      margin: const EdgeInsets.only(
        top: 100,
        left: 25,
        right: 25,
      ),
      decoration: appBoxShadow(),
      alignment: Alignment.center,
      child: Text(
        buttonText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}