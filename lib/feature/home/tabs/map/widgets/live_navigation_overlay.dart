import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

import '../bloc/map_state.dart';

class LiveNavigationOverlay extends StatelessWidget {
  final MapState state;
  final VoidCallback onStopNavigation;
  final VoidCallback onRecenter;
  final bool isFollowingUser;

  const LiveNavigationOverlay({
    super.key,
    required this.state,
    required this.onStopNavigation,
    required this.onRecenter,
    required this.isFollowingUser,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isLiveNavigating || state.currentRoute == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);

    final currentStep = (state.currentStepIndex < state.currentRoute!.steps.length)
        ? state.currentRoute!.steps[state.currentStepIndex]
        : null;

    return Stack(
      children: [
        // Instruction Bar at the Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.all(12.r),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor, blurRadius: 16, spreadRadius: 1)
                ],
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current step instruction
                  if (currentStep != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.navigation_rounded,
                              color: primary, size: 22.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStep.instruction,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${currentStep.distance} · ${currentStep.duration}',
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.5),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Overall ETA
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded,
                              color: primary, size: 16.r),
                          SizedBox(width: 6.w),
                          Text(
                            '${state.currentRoute!.distance} · ${state.currentRoute!.duration} total',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.6),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Step progress bar
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).mapStepProgress(state.currentStepIndex + 1, state.currentRoute!.steps.length),
                          style: TextStyle(
                              color: onSurface.withValues(alpha: 0.5), fontSize: 12.sp),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (state.currentStepIndex + 1) /
                                state.currentRoute!.steps.length,
                            backgroundColor: onSurface.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(primary),
                            minHeight: 4.h,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: onStopNavigation,
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.stop_rounded,
                                color: Colors.red, size: 18.r),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Re-center Button
        if (!isFollowingUser)
          PositionedDirectional(
            bottom: 30.h,
            end: 16.w,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: primary,
              onPressed: onRecenter,
              child: Icon(Icons.my_location_rounded,
                  color: Colors.white, size: 20.r),
            ),
          ),
      ],
    );
  }
}
