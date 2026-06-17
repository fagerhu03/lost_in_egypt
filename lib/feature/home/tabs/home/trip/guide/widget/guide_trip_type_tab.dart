import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/theme/theme.dart';

class GuideTripTypeTab extends StatelessWidget {
  final String title;
  final bool selected;

  const GuideTripTypeTab({
    super.key,
    required this.title,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // ✅ Selected background changes with theme
    final activeColor = isDark ? AppColors.darkBox : AppColors.lightBox.withValues(alpha: 0.5);

    // ✅ Unselected background also theme-aware + lighter
    final inactiveBg = isDark
        ? AppColors.darkBox.withValues(alpha: 0.18)
        : AppColors.lightPatternOverlay.withValues(alpha: 0.40);

    // ✅ Text colors
    final inactiveText = isDark
        ? AppColors.darkText.withValues(alpha: 0.65)
        : const Color(0xFF7A4B1D).withValues(alpha: 0.80);

    final selectedTextColor = isDark
        ? AppColors.darkText
        : AppColors.lightFieldText; // white

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 52.h,
        decoration: BoxDecoration(
          color: selected ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? AppColors.darkText.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? selectedTextColor : inactiveText,
            fontSize: 20.sp,
            height: 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
