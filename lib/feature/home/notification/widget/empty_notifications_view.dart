import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyNotificationsView extends StatelessWidget {
  final VoidCallback onTapSettings;

  const EmptyNotificationsView({super.key, required this.onTapSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(
              Icons.mail_outline,
              color: primary.withValues(alpha: 0.85),
              size: 34.r,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "No notifications yet",
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.87),
              fontFamily: "Marcellus",
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "Your notifications will appear here once\nyou start getting them.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.55),
              fontFamily: "Marcellus",
              fontSize: 12.sp,
              height: 1.3,
            ),
          ),
          SizedBox(height: 12.h),
          InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: onTapSettings,
            child: Text(
              "Notification Settings",
              style: TextStyle(
                color: primary,
                fontFamily: "Marcellus",
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
