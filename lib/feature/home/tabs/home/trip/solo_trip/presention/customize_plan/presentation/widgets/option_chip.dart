import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../../../../../theme/theme.dart';

class OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;

  const OptionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkPrimaryButton
              : (isDark ? AppColors.darkPatternOverlay : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.darkPrimaryButton
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: TextStyle(fontSize: 15.sp)),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
