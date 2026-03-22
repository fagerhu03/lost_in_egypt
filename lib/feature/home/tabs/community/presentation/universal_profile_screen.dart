import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart' as dartz;

import 'package:lost_in_egypt/theme/theme.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/core/widgets/universal_report_dialog.dart';
import 'package:lost_in_egypt/feature/admin/data/models/report_model.dart';
import 'package:lost_in_egypt/feature/admin/domain/repositories/reports_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_constants.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_model.dart';
import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/tours/domain/repositories/tours_repository.dart';
import 'package:lost_in_egypt/feature/tours/presentation/widgets/tour_card.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/presentation/edit_profile_screen_enhanced.dart';

class UniversalProfileScreen extends StatefulWidget {
  final UserModel user;

  const UniversalProfileScreen({super.key, required this.user});

  @override
  State<UniversalProfileScreen> createState() => _UniversalProfileScreenState();
}

class _UniversalProfileScreenState extends State<UniversalProfileScreen> {
  bool _expandedBio = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.scaffoldBackgroundColor : (widget.user.isVerifiedGuide ? const Color(0xFFFFFEF0) : theme.scaffoldBackgroundColor);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final surface = theme.colorScheme.surface;
    final isCurrentUser = FirebaseAuth.instance.currentUser?.uid == widget.user.id;
    
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.3 : 0.5,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new, color: titleColor, size: 22),
                      ),
                      Expanded(
                        child: Text(
                          widget.user.isVerifiedGuide ? 'Guide Profile' : 'Traveler Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Marcellus',
                          ),
                        ),
                      ),
                      if (!isCurrentUser)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: titleColor),
                          onSelected: (value) {
                            if (value == 'report') {
                              UniversalReportDialog.show(
                                context,
                                reportType: ReportType.user,
                                reportedItemId: widget.user.id,
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
                        )
                      else
                        const SizedBox(width: 24), // Placeholder to balance back button
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? surface.withOpacity(0.85) : bg.withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border.all(color: titleColor.withOpacity(0.2), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                          child: widget.user.isVerifiedGuide ? _buildGuideProfile(context, titleColor) : _buildTouristProfile(context, titleColor),
                        ),
                      ),
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

  Widget _buildTouristProfile(BuildContext context, Color titleColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final displayName = "${widget.user.firstName} ${widget.user.lastName}".trim();
    
    final secretBadgeIds = BadgeConstants.allBadges.where((b) => b.isSecret).map((b) => b.id).toList();
    final int trueVisitedCount = widget.user.visitedLandmarks.where((id) => !secretBadgeIds.contains(id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(color: titleColor.withOpacity(0.5), width: 3),
            image: widget.user.profileImageUrl.isNotEmpty 
              ? DecorationImage(
                  image: CachedNetworkImageProvider(widget.user.profileImageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          ),
          child: widget.user.profileImageUrl.isEmpty
              ? Icon(Icons.person, size: 60, color: onSurface.withOpacity(0.5))
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontFamily: "Marcellus",
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.user.username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@${widget.user.username}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontFamily: "Marcellus",
            ),
          ),
        ],
        if (widget.user.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.user.bio,
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 14),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: titleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                "$trueVisitedCount Places Visited",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Achievements',
            style: TextStyle(color: titleColor, fontSize: 20, fontFamily: "Marcellus", fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final displayBadges = BadgeConstants.allBadges.where((b) {
              return !b.isSecret || widget.user.visitedLandmarks.contains(b.id);
            }).toList();
            
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: List.generate(
                displayBadges.length,
                (index) {
                  final badge = displayBadges[index];
                  final isUnlocked = widget.user.visitedLandmarks.contains(badge.id) || 
                      (trueVisitedCount >= badge.requiredVisits && !badge.isSecret);
                  return _buildBadgeIcon(badge, isUnlocked, onSurface);
                },
              ),
            );
          }
        ),
      ],
    );
  }

  Widget _buildGuideProfile(BuildContext context, Color titleColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UniversalGuideHeaderCard(guide: widget.user),
        const SizedBox(height: 16),
        _UniversalInfoStrip(guide: widget.user),
        const SizedBox(height: 24),
        Text(
          'About Me',
          style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Marcellus'),
        ),
        const SizedBox(height: 8),
        Text(
          widget.user.bio.isNotEmpty 
            ? widget.user.bio 
            : 'This guide has not provided a bio yet. Contact them to learn more about their experiences and offerings.',
          maxLines: _expandedBio ? null : 4,
          overflow: _expandedBio ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.85),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (widget.user.bio.length > 100)
          GestureDetector(
            onTap: () => setState(() => _expandedBio = !_expandedBio),
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _expandedBio ? 'View less' : 'View more',
                style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Hosted Tours',
          style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Marcellus'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 400,
          child: _UniversalGuideToursList(guideId: widget.user.id),
        ),
        if (FirebaseAuth.instance.currentUser?.uid == widget.user.id) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: titleColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreenEnhanced()));
              },
              child: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadgeIcon(BadgeModel badge, bool isUnlocked, Color onSurface) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
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
              ? Icon(badge.iconData, color: Colors.amber, size: 24)
              : const Icon(Icons.lock, color: Colors.grey, size: 20),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
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

class _UniversalGuideHeaderCard extends StatelessWidget {
  final UserModel guide;

  const _UniversalGuideHeaderCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkText : const Color(0xFF7A4B1D);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: titleColor.withOpacity(0.3), width: 2),
                image: guide.profileImageUrl.isNotEmpty 
                    ? DecorationImage(image: NetworkImage(guide.profileImageUrl), fit: BoxFit.cover)
                    : null,
                color: isDark ? const Color(0xFF3E2C1E) : const Color(0xFF7A4B1D),
              ),
              child: guide.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white70, size: 50)
                  : null,
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: isDark ? Colors.black54 : Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.verified, color: Colors.blue, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${guide.firstName} ${guide.lastName}'.trim(),
                style: TextStyle(fontSize: 24, color: titleColor, fontWeight: FontWeight.bold, height: 1.1),
              ),
              if (guide.username.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '@${guide.username}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontFamily: "Marcellus",
                  ),
                ),
              ],
              const SizedBox(height: 6),
              if (guide.reviewCount == 0)
                Text("New Guide", style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600))
              else 
                Row(
                  children: [
                    Text('${guide.rating.toStringAsFixed(1)} ', style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.bold)),
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    Text(' (${guide.reviewCount} reviews)', style: TextStyle(color: titleColor.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: titleColor.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    guide.nationality.isNotEmpty ? guide.nationality : 'Egypt',
                    style: TextStyle(fontSize: 14, color: titleColor.withOpacity(0.8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UniversalInfoStrip extends StatelessWidget {
  final UserModel guide;

  const _UniversalInfoStrip({required this.guide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkText.withOpacity(0.18) : const Color(0xFFBDA47D);
    final titleColor = isDark ? AppColors.darkText : const Color(0xFF7A4B1D);
    final subColor = isDark ? AppColors.darkText.withOpacity(0.6) : const Color(0xFFB6A17F);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildInfoItem(Icons.language, guide.certifiedLanguages.isNotEmpty ? guide.certifiedLanguages.join(', ') : 'EN/AR', 'Languages', titleColor, subColor)),
          Container(width: 1, height: 40, color: borderColor),
          Expanded(child: _buildInfoItem(Icons.verified_user, 'Licensed', 'Status', titleColor, subColor)),
          Container(width: 1, height: 40, color: borderColor),
          Expanded(child: _buildInfoItem(Icons.star_half_rounded, guide.reviewCount == 0 ? 'New' : guide.rating.toStringAsFixed(1), 'Rating', titleColor, subColor)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle, Color titleColor, Color subColor) {
    return Column(
      children: [
        Icon(icon, color: titleColor.withOpacity(0.8), size: 24),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(subtitle, style: TextStyle(color: subColor, fontSize: 11)),
      ],
    );
  }
}

class _UniversalGuideToursList extends StatefulWidget {
  final String guideId;

  const _UniversalGuideToursList({required this.guideId});

  @override
  State<_UniversalGuideToursList> createState() => _UniversalGuideToursListState();
}

class _UniversalGuideToursListState extends State<_UniversalGuideToursList> {
  late Future<dartz.Either<dynamic, List<TourEntity>>> _toursFuture;

  @override
  void initState() {
    super.initState();
    _toursFuture = sl<ToursRepository>().getToursForGuide(widget.guideId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dartz.Either<dynamic, List<TourEntity>>>(
      future: _toursFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasData) {
          return snapshot.data!.fold(
            (failure) => const Center(child: Text('Failed to load tours')),
            (tours) {
              if (tours.isEmpty) return const Center(child: Text('No hosted tours yet.'));
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tours.length,
                clipBehavior: Clip.none,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(width: 250, child: TourCard(tour: tours[index]));
                },
              );
            },
          );
        }
        return const Center(child: Text('Failed to load tours'));
      },
    );
  }
}
