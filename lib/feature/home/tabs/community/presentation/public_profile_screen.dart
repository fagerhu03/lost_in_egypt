import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../auth/data/models/user.dart';
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
    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    final String displayName = "${user.firstName} ${user.lastName}".trim();
    final String profileUrl = user.profileImageUrl;

    final Color cardColor = isDark ? surface.withOpacity(0.5) : const Color(0xFFF3F2E4);

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
                errorBuilder: (c, o, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new, color: onSurface, size: 20),
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
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text('Report Profile'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 50),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: isDark ? Border.all(color: borderColor) : null,
                                boxShadow: isDark ? [] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 60),
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: isDark ? onSurface : const Color(0xFF6B3A28),
                                      fontSize: 22,
                                      fontFamily: "Marcellus",
                                    ),
                                  ),
                                  if (user.bio.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        user.bio,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: onSurface.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.place, color: Colors.amber, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          "$trueVisitedCount Places Visited",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: onSurface.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Builder(
                                      builder: (context) {
                                        final displayBadges = BadgeConstants.allBadges.where((b) {
                                          return !b.isSecret || user.visitedLandmarks.contains(b.id);
                                        }).toList();
                                        
                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 6,
                                          runSpacing: 10,
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
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: surface,
                                border: Border.all(color: cardColor, width: 4),
                              ),
                              child: profileUrl.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: profileUrl, fit: BoxFit.cover, errorWidget: (_, _, _) => Icon(Icons.person, size: 60, color: onSurface.withOpacity(0.5)))
                                  : Icon(Icons.person, size: 60, color: onSurface.withOpacity(0.5)),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? Colors.amber.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
            border: Border.all(
              color: isUnlocked ? Colors.amber : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: isUnlocked
              ? Icon(badge.iconData, color: Colors.amber, size: 22)
              : const Icon(Icons.lock, color: Colors.grey, size: 18),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          child: Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              color: isUnlocked ? onSurface : onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
