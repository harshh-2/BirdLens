import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget appImage({required String imagePath,double width = 16,double height = 16}) {
return Image.asset(imagePath, width: width.w,height: height.h,);
}