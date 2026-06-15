import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../../../theme/theme.dart';

class QuizScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String nextText;
  final int stepIndex;
  final int totalSteps;

  const QuizScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onNext,
    required this.onBack,
    required this.stepIndex,
    this.totalSteps = 5,
    this.nextText = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.darkPrimaryButton;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg =
        isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final labelColor = isDark ? AppColors.darkText : AppColors.lightBox;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10.h),

            // ── Header: back button + "Step X of 5" ───────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16.r,
                        color: primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Step ${stepIndex + 1} of $totalSteps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.55),
                        letterSpacing: 0.5,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      ),
                    ),
                  ),
                  // Invisible balance for the back button
                  SizedBox(width: 38.w),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            // ── Gold progress bar ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: (stepIndex + 1) / totalSteps,
                  minHeight: 5.h,
                  backgroundColor: primary.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // ── Content card ───────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 16.h),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Expanded(child: child),
                    SizedBox(height: 14.h),

                    // ── Next / Finish ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: onNext,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              nextText,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              nextText == 'Finish'
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16.r,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
