import 'package:flutter/material.dart';
import 'package:birdlens/widgets/app_shadows.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget AppButton({
  required String buttonText,
  required VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 325.w,
      height: 50.h,
      margin: const EdgeInsets.only(
        top: 50,
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