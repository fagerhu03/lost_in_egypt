import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/models/route_info.dart';

class NavigationInfoBar extends StatelessWidget {
  final RouteInfo routeInfo;
  final String selectedMode;
  final bool isLoadingRoute;
  final VoidCallback onClose;
  final VoidCallback onStartNavigation;
  final VoidCallback onShowSteps;
  final ValueChanged<String> onModeChanged;

  const NavigationInfoBar({
    super.key,
    required this.routeInfo,
    required this.selectedMode,
    required this.isLoadingRoute,
    required this.onClose,
    required this.onStartNavigation,
    required this.onShowSteps,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.15);

    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── DRAG HANDLE ──────────────────────
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // ─── TRAVEL MODE SELECTOR ─────────────
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
            child: Row(
              children: [
                _buildModeChip(
                  context: context,
                  icon: Icons.directions_car_rounded,
                  label: 'Drive',
                  mode: 'driving',
                  isSelected: selectedMode == 'driving',
                  primary: primary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                SizedBox(width: 8.w),
                _buildModeChip(
                  context: context,
                  icon: Icons.directions_walk_rounded,
                  label: 'Walk',
                  mode: 'walking',
                  isSelected: selectedMode == 'walking',
                  primary: primary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                SizedBox(width: 8.w),
                _buildModeChip(
                  context: context,
                  icon: Icons.directions_transit_rounded,
                  label: 'Transit',
                  mode: 'transit',
                  isSelected: selectedMode == 'transit',
                  primary: primary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const Spacer(),
                // Close button
                Material(
                  color: onSurface.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: onClose,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36.r,
                      height: 36.r,
                      child: Icon(
                        Icons.close_rounded,
                        color: onSurface.withValues(alpha: 0.6),
                        size: 20.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── LOADING INDICATOR ────────────────
          if (isLoadingRoute)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Finding route...',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),

          // ─── ROUTE INFO ───────────────────────
          if (!isLoadingRoute)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
              child: Row(
                children: [
                  // Duration
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeInfo.duration,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        routeInfo.distance,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Steps button
                  if (routeInfo.steps.isNotEmpty)
                    Material(
                      color: onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10.r),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: onShowSteps,
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.list_alt_rounded,
                                color: onSurface.withValues(alpha: 0.7),
                                size: 18.r,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '${routeInfo.steps.length} steps',
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.7),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ─── START NAVIGATION BUTTON ──────────
          if (!isLoadingRoute)
            Padding(
              padding: EdgeInsets.all(16.r),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: onStartNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.4),
                  ),
                  icon: Icon(Icons.navigation_rounded, size: 22.r),
                  label: Text(
                    'Start Navigation',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String mode,
    required bool isSelected,
    required Color primary,
    required Color onSurface,
    required bool isDark,
  }) {
    return Material(
      color: isSelected
          ? primary.withValues(alpha: isDark ? 0.25 : 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => onModeChanged(mode),
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected
                  ? primary.withValues(alpha: 0.5)
                  : onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.r,
                color: isSelected ? primary : onSurface.withValues(alpha: 0.5),
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
