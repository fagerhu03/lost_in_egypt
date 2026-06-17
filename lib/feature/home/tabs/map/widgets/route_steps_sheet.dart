import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/models/route_info.dart';

class RouteStepsSheet extends StatelessWidget {
  final RouteInfo routeInfo;

  const RouteStepsSheet({super.key, required this.routeInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                child: Row(
                  children: [
                    Icon(Icons.route_rounded, color: primary, size: 24.r),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mapRouteSteps,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          '${routeInfo.distance} • ${routeInfo.duration}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(
                height: 24.h,
                color: onSurface.withValues(alpha: 0.08),
              ),

              // Steps
              ...routeInfo.steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isLast = index == routeInfo.steps.length - 1;

                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline
                        Column(
                          children: [
                            Container(
                              width: 28.r,
                              height: 28.r,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha:
                                    isDark ? 0.20 : 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: primary.withValues(alpha: 0.2),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 14.w),
                        // Step info
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.instruction,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: onSurface.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.straighten_rounded,
                                      size: 14.r,
                                      color: onSurface.withValues(alpha: 0.4),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      step.distance,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: onSurface.withValues(alpha: 0.45),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14.r,
                                      color: onSurface.withValues(alpha: 0.4),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      step.duration,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: onSurface.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Destination marker
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Container(
                      width: 28.r,
                      height: 28.r,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.flag_rounded,
                        size: 14.r,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      l10n.mapArriveDestination,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }
}
