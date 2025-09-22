import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final void Function()? onTap;

  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.4), // changed to gray
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: Colors.grey.withOpacity(0.3),    // gray splash
        highlightColor: Colors.grey.withOpacity(0.1), // gray highlight
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3), // gray shadow
                offset: const Offset(0, 6),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
