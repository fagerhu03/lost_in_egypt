import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapLoadingOverlay extends StatelessWidget {
  final bool isLoading;

  const MapLoadingOverlay({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);

    Color chipBg({bool strong = false}) =>
        surface.withValues(alpha: strong ? (isDark ? 0.92 : 0.95) : 0.92);

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: chipBg(strong: true),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
                border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primary)),
                  SizedBox(width: 10.w),
                  Text("Loading...",
                      style: TextStyle(color: onSurface.withValues(alpha: 0.9))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
