import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {

  final String title;
  final String subtitle;

  const LoadingDialog({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [

            const SizedBox(
              width: 60,
              height: 60,

              child:
                  CircularProgressIndicator(
                strokeWidth: 4,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,

              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              subtitle,
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}