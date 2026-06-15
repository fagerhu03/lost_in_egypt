import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/quiz_scaffold.dart';

class TripTimeStep extends StatelessWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const TripTimeStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return QuizScaffold(
      title: 'Day trips or night out?',
      stepIndex: 3,
      onNext: onNext,
      onBack: onBack,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimeCard(
            label: 'Day',
            emoji: '☀️',
            description: 'Temples, markets,\nand outdoor adventures',
            isSelected: controller.plan.tripTimes.contains('Day'),
            activeColor: const Color(0xFFF59E0B),
            onTap: () => controller.toggleTripTime('Day'),
          ),
          SizedBox(width: 12.w),
          _TimeCard(
            label: 'Night',
            emoji: '🌙',
            description: 'Dining, nightlife,\nand entertainment',
            isSelected: controller.plan.tripTimes.contains('Night'),
            activeColor: const Color(0xFF6366F1),
            onTap: () => controller.toggleTripTime('Night'),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final String emoji;
  final String description;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TimeCard({
    required this.label,
    required this.emoji,
    required this.description,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF0B1D26) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8E2C8) : const Color(0xFF3D3A2F);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : surfaceBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? activeColor : textColor.withValues(alpha: 0.12),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 52.sp),
              ),
              SizedBox(height: 14.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? activeColor : textColor,
                  fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.5,
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.8)
                        : textColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
