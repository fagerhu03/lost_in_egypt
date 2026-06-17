import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

class YourPlanScreen extends StatelessWidget {
  const YourPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.accountMembership, style: const TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo'])),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 40.h),
        children: [
          // Current plan card
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A3040), const Color(0xFF0B1D26)]
                    : [const Color(0xFFFFF8DC), const Color(0xFFFCFBE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: primary, size: 28.r),
                    SizedBox(width: 10.w),
                    Text(
                      l10n.planExplorerFree,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        l10n.planActive,
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  l10n.planCurrentDesc,
                  style: TextStyle(fontSize: 13.sp, color: onSurface.withValues(alpha: 0.65), height: 1.5),
                ),
              ],
            ),
          ),

          SizedBox(height: 28.h),

          Text(
            l10n.planWhatsIncluded,
            style: TextStyle(
              fontSize: 17.sp,
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          SizedBox(height: 14.h),

          ...[
            (Icons.camera_alt_outlined, l10n.planFeatDiscoveryTitle, l10n.planFeatDiscoveryDesc),
            (Icons.auto_stories_outlined, l10n.planFeatStoriesTitle, l10n.planFeatStoriesDesc),
            (Icons.map_outlined, l10n.planFeatMapTitle, l10n.planFeatMapDesc),
            (Icons.tour_outlined, l10n.planFeatToursTitle, l10n.planFeatToursDesc),
            (Icons.emoji_events_outlined, l10n.planFeatBadgesTitle, l10n.planFeatBadgesDesc),
            (Icons.people_outline, l10n.planFeatCommunityTitle, l10n.planFeatCommunityDesc),
            (Icons.translate_outlined, l10n.planFeatTranslatorTitle, l10n.planFeatTranslatorDesc),
            (Icons.currency_exchange_outlined, l10n.planFeatCurrencyTitle, l10n.planFeatCurrencyDesc),
            (Icons.notifications_outlined, l10n.planFeatNotificationsTitle, l10n.planFeatNotificationsDesc),
          ].map((e) => _FeatureRow(
                icon: e.$1,
                title: e.$2,
                subtitle: e.$3,
                primary: primary,
                surface: surface,
                onSurface: onSurface,
                isDark: isDark,
              )),

          SizedBox(height: 28.h),
          Divider(color: onSurface.withValues(alpha: 0.1)),
          SizedBox(height: 20.h),

          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch_outlined, color: primary, size: 22.r),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.planComingSoon,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.planComingSoonDesc,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: onSurface.withValues(alpha: 0.65),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final Color surface;
  final Color onSurface;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 18.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600, color: onSurface)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12.sp, color: onSurface.withValues(alpha: 0.6), height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 18.r),
        ],
      ),
    );
  }
}
