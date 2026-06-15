import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../auth/data/models/user.dart';
import '../../../../../core/widgets/shimmer_avatar.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_constants.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_model.dart';
import '../../../../../core/widgets/universal_report_dialog.dart';
import '../../../../admin/data/models/report_model.dart';
import '../../../../admin/domain/repositories/reports_repository.dart';
import 'package:get_it/get_it.dart';

class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    final patternOpacity = isDark ? 0.20 : 0.40;
    final borderColor =
    (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.10 : 0.06);

    final String displayName = "${user.firstName} ${user.lastName}".trim();
    final String profileUrl = user.profileImageUrl;

    final Color cardColor = isDark ? surface.withValues(alpha: 0.5) : const Color(0xFFF3F2E4);

    final secretBadgeIds = BadgeConstants.allBadges.where((b) => b.isSecret).map((b) => b.id).toList();
    final int trueVisitedCount = user.visitedLandmarks.where((id) => !secretBadgeIds.contains(id)).length;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new, color: onSurface, size: 20.r),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: onSurface),
                        onSelected: (value) {
                          if (value == 'report') {
                            UniversalReportDialog.show(
                              context,
                              reportType: ReportType.user,
                              reportedItemId: user.id,
                              repository: GetIt.I<ReportsRepository>(),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag, color: Colors.orange, size: 20.r),
                                SizedBox(width: 8.w),
                                const Text('Report Profile'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 50.h),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24.r),
                                border: isDark ? Border.all(color: borderColor) : null,
                                boxShadow: isDark ? [] : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 60.h),
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: isDark ? onSurface : const Color(0xFF6B3A28),
                                      fontSize: 22.sp,
                                      fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                                    ),
                                  ),
                                  if (user.bio.isNotEmpty) ...[
                                    SizedBox(height: 8.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                                      child: Text(
                                        user.bio,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: onSurface.withValues(alpha: 0.7),
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 16.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.place, color: Colors.amber, size: 18.r),
                                        SizedBox(width: 8.w),
                                        Text(
                                          "$trueVisitedCount Places Visited",
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: onSurface.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    child: Builder(
                                      builder: (context) {
                                        final displayBadges = BadgeConstants.allBadges.where((b) {
                                          return !b.isSecret || user.visitedLandmarks.contains(b.id);
                                        }).toList();
                                        
                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 6.w,
                                          runSpacing: 10.h,
                                          children: List.generate(
                                            displayBadges.length,
                                            (index) {
                                              final badge = displayBadges[index];
                                              final isUnlocked = user.visitedLandmarks.contains(badge.id) || 
                                                  (trueVisitedCount >= badge.requiredVisits && !badge.isSecret);
                                              return _buildBadgeIcon(badge, isUnlocked, onSurface);
                                            },
                                          ),
                                        );
                                      }
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: cardColor, width: 4),
                              ),
                              child: ShimmerAvatar(
                                url: profileUrl,
                                radius: 46.r,
                                iconSize: 60.r,
                                fallbackBackgroundColor: surface,
                                fallbackIconColor: onSurface.withValues(alpha: 0.5),
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
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(BadgeModel badge, bool isUnlocked, Color onSurface) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border.all(
              color: isUnlocked ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: isUnlocked
              ? Icon(badge.iconData, color: Colors.amber, size: 22.r)
              : Icon(Icons.lock, color: Colors.grey, size: 18.r),
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: 64.w,
          child: Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              color: isUnlocked ? onSurface : onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
