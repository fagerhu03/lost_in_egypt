import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/shimmer_avatar.dart';

class NotifCard extends StatelessWidget {
  final bool isRead;
  final String senderName;
  final String message;
  final String timeText;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  const NotifCard({
    super.key,
    required this.isRead,
    required this.senderName,
    required this.message,
    required this.timeText,
    required this.avatarUrl,
    required this.onTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final unreadBorderColor =
        isDark ? primary.withValues(alpha: 0.35) : const Color(0xFFC79A00).withValues(alpha: 0.35);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isRead ? Colors.transparent : unreadBorderColor,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: ShimmerAvatar(
                  url: avatarUrl,
                  radius: 17.r,
                  iconSize: 20.r,
                  fallbackBackgroundColor: primary.withValues(alpha: 0.12),
                  fallbackIconColor: onSurface.withValues(alpha: 0.65),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: onSurface.withValues(alpha: 0.87),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 12.sp,
                        color: onSurface.withValues(alpha: 0.65),
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(
                            fontFamily: "Marcellus",
                            fontSize: 11.sp,
                            color: onSurface.withValues(alpha: 0.50),
                          ),
                        ),
                        const Spacer(),
                        if (!isRead)
                          Container(
                            width: 8.r,
                            height: 8.r,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
