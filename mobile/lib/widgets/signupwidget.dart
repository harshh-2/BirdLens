import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:birdlens/widgets/text_styles.dart';
import 'package:birdlens/widgets/app_shadows.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:birdlens/widgets/image_widget.dart';

AppBar buildAppbar(){
  return AppBar(
    bottom: PreferredSize(preferredSize:Size.fromHeight(1), child: Container()),
    title:BoldText(text:"SignUp to BirdLens"),);
}

Widget _Button({
  required String buttonText,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 325,
      height: 50,
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

Widget appTextfield({required String boxtitle,  required TextEditingController controller,required TextInputType keyboardType, required String imgPath,required String hintText,required bool isPasswordField, bool isPasswordVisible = false,  VoidCallback? onTogglePassword,}){
  return Container(
    padding: EdgeInsets.only(left:25.w,right:25.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Normal16Text(text:boxtitle),
        SizedBox(
          height: 5.h,
        ),
        Container(
          height:50.h,
          width: 325.w,
          decoration: appBoxDecorationTextField(),
          child:Row(
            children: [
              Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: appImage(imagePath: imgPath),
              ),
              Expanded(     
                child:TextField(
                controller:controller,
                obscureText: isPasswordField ? !isPasswordVisible : false,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: isPasswordField
                ? IconButton(
                icon: Icon(
                    isPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
                ),
            onPressed: onTogglePassword,
          )
        : null,
                  ), 
                onChanged: (value){},
                maxLines: 1,
                autocorrect: false,
                 
                  ), 
              ),
            ],
          )
        )
      ]
    ),

  );
}

BoxDecoration appBoxDecorationTextField(
{double radius = 15, sR=1, bR=2})
 {
return BoxDecoration(
color: colors['card']!,
borderRadius: BorderRadius.circular(radius),
border: Border.all(color:colors['border']!),
); // BoxDecoration
 }