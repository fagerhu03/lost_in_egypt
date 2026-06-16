import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/customize_plan/presentation/pages/quiz_flow_screen.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../../../../../../../theme/theme.dart';

class CustomizePlanCard extends StatelessWidget {
  final VoidCallback? onTap;

  const CustomizePlanCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QuizFlowScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 40.w),
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkPatternOverlay
              : const Color(0xFFFFFEF0),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 47.r,
              color: isDark ? AppColors.darkPrimaryButton : AppColors.lightBox,
            ),
            SizedBox(width: 18.w),
            Flexible(
              child: Text(
                AppLocalizations.of(context).soloCustomizeOwnPlan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightBox,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
