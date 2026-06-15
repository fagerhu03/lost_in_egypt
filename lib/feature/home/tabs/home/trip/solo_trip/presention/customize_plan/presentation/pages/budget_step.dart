import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../../../../../theme/theme.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/quiz_scaffold.dart';

class BudgetStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BudgetStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  static String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).round()}K EGP';
    return '${v.toInt()} EGP';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.darkPrimaryButton;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final labelColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final minB = controller.plan.minBudget;
    final maxB = controller.plan.maxBudget;

    return QuizScaffold(
      title: "What's your budget?",
      stepIndex: 4,
      onNext: onNext,
      onBack: onBack,
      nextText: 'Finish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Preset buttons ───────────────────────────────────────────────
          Row(
            children: [
              _PresetBtn(
                label: 'Budget',
                sub: '< 3K',
                isSelected: minB == 500 && maxB == 3000,
                color: const Color(0xFF22C55E),
                onTap: () => controller.updateBudgetRange(500, 3000),
              ),
              SizedBox(width: 8.w),
              _PresetBtn(
                label: 'Mid-range',
                sub: '3K–10K',
                isSelected: minB == 3000 && maxB == 10000,
                color: primary,
                onTap: () => controller.updateBudgetRange(3000, 10000),
              ),
              SizedBox(width: 8.w),
              _PresetBtn(
                label: 'Luxury',
                sub: '10K+',
                isSelected: minB == 10000 && maxB == 30000,
                color: const Color(0xFFA855F7),
                onTap: () => controller.updateBudgetRange(10000, 30000),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // ── Range display ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(minB),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                ),
              ),
              Text(
                '—',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.35),
                  fontSize: 16.sp,
                ),
              ),
              Text(
                _fmt(maxB),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // ── RangeSlider ──────────────────────────────────────────────────
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primary,
              inactiveTrackColor: primary.withValues(alpha: 0.18),
              thumbColor: primary,
              overlayColor: primary.withValues(alpha: 0.12),
              trackHeight: 4.h,
            ),
            child: RangeSlider(
              values: RangeValues(minB, maxB),
              min: 500,
              max: 30000,
              divisions: 59,
              onChanged: (values) =>
                  controller.updateBudgetRange(values.start, values.end),
            ),
          ),

          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '500 EGP',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textColor.withValues(alpha: 0.40),
                ),
              ),
              Text(
                '30K EGP',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textColor.withValues(alpha: 0.40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetBtn extends StatelessWidget {
  final String label;
  final String sub;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PresetBtn({
    required this.label,
    required this.sub,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF0B1D26) : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : surfaceBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : color.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
