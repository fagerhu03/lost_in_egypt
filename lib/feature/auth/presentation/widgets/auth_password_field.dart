import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onVisibilityToggle;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onVisibilityToggle,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7A8450).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 3.h),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        style: TextStyle(
          color: Colors.white,
          fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
          fontSize: 15.sp,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white60,
            fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
            fontSize: 15.sp,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 20.r,
            ),
            onPressed: onVisibilityToggle,
          ),
        ),
      ),
    );
  }
}
