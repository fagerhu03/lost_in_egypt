import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56.r, color: onSurface.withValues(alpha: 0.25)),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.65),
                fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 20.h),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 18.r),
                label: Text(
                  AppLocalizations.of(context).commonTryAgain,
                  style: const TextStyle(
                      fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo']),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
