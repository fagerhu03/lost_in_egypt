import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrianglePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final int index;
  final int total;
  final VoidCallback onNext;
  final String buttonLabel;

  const TrianglePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.total,
    required this.onNext,
    this.buttonLabel = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TriangleClipper(),
      child: Container(
        height: 360.h,
        width: double.infinity,
        color: const Color(0xffFCFBE8).withValues(alpha: 0.7),
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50.h),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  title,
                  key: ValueKey('title_$index'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Marcellus',
                    color: const Color(0xFF4D5420),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  subtitle,
                  key: ValueKey('sub_$index'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.4,
                    fontFamily: 'Marcellus',
                    color: const Color(0xFF4D5420),
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              Material(
                color: const Color(0xFF7A8450),
                borderRadius: BorderRadius.circular(20.r),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: onNext,
                  child: Container(
                    width: buttonLabel == 'Next' ? 110.w : 160.w,
                    height: 45.h,
                    alignment: Alignment.center,
                    child: Text(
                      buttonLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontFamily: 'Marcellus',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
              _dots(index, total),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dots(int active, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = active == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isActive ? 22.w : 9.w,
          height: 9.h,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4D5420) : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(5.r),
          ),
        );
      }),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.18);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.18);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
