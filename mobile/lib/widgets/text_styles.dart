import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';

Widget BoldText({required String text}){
 return Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
            color:colors['text'],
            fontWeight: FontWeight.bold,
            fontSize: 24
                ),
              );
}

Widget Normal16Text({required String text}){
   return Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
            color:colors['text'],
            fontWeight: FontWeight.normal,
            fontSize: 16
                ),
              );
}