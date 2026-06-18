import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';

BoxDecoration appBoxShadow(
{double radius = 15, double sR=1,double  bR=2})
 {
return BoxDecoration(
color: colors['card']!,
borderRadius: BorderRadius.circular(radius),
boxShadow: [
BoxShadow(
color: colors['shadow']!,
spreadRadius: sR,
blurRadius: bR,
offset: const Offset(0, 1)) // BoxShadow
]); // BoxDecoration
 }