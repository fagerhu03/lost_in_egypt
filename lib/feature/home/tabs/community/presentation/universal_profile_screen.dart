import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_avatar.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:url_launcher/url_launcher.dart';

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
import 'package:lost_in_egypt/feature/home/tabs/community/data/model/community_post_model.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/community_post_card.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/post_detail_screen.dart';

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
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new, color: titleColor, size: 22.r),
                      ),
                      Expanded(
                        child: Text(
                          widget.user.isVerifiedGuide ? 'Guide Profile' : 'Traveler Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
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
                        )
                      else
                        SizedBox(width: 24.w), // Placeholder to balance back button
                    ],
                  ),
                ),
                // Main Content with About/Posts tabs
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? surface.withValues(alpha: 0.85) : bg.withValues(alpha: 0.9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border.all(color: titleColor.withValues(alpha: 0.2), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: titleColor,
                                unselectedLabelColor: titleColor.withValues(alpha: 0.45),
                                indicatorColor: theme.colorScheme.primary,
                                labelStyle: TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'], fontWeight: FontWeight.bold, fontSize: 14.sp),
                                tabs: const [Tab(text: 'About'), Tab(text: 'Posts')],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    SingleChildScrollView(
                                      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
                                      child: widget.user.isVerifiedGuide
                                          ? _buildGuideProfile(context, titleColor)
                                          : _buildTouristProfile(context, titleColor),
                                    ),
                                    _buildUserPostsTab(context, titleColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildUserPostsTab(BuildContext context, Color titleColor) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return StreamBuilder<QuerySnapshot>(
      stream: GetIt.I<FirebaseFirestore>()
          .collection('community_posts')
          .where('userId', isEqualTo: widget.user.id)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.post_add_outlined, size: 52.r, color: onSurface.withValues(alpha: 0.2)),
                SizedBox(height: 12.h),
                Text('No posts yet', style: TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'], fontSize: 16.sp, color: onSurface.withValues(alpha: 0.45))),
              ],
            ),
          );
        }
        final posts = docs.map((d) => CommunityPostModel.fromSnapshot(d)).toList();
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 32.h),
          itemCount: posts.length,
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (context, i) {
            final post = posts[i];
            return CommunityPostCard(
              key: ValueKey(post.id),
              post: post,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
            );
          },
        );
      },
    );
  }

  Widget _buildTouristProfile(BuildContext context, Color titleColor) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final displayName = "${widget.user.firstName} ${widget.user.lastName}".trim();
    
    final secretBadgeIds = BadgeConstants.allBadges.where((b) => b.isSecret).map((b) => b.id).toList();
    final int trueVisitedCount = widget.user.visitedLandmarks.where((id) => !secretBadgeIds.contains(id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          padding: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: titleColor.withValues(alpha: 0.5), width: 3),
          ),
          child: ShimmerAvatar(
            url: widget.user.profileImageUrl,
            radius: 47.r,
            iconSize: 60.r,
            fallbackBackgroundColor: theme.colorScheme.surface,
            fallbackIconColor: onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          displayName,
          style: TextStyle(
            color: titleColor,
            fontSize: 24.sp,
            fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.user.username.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            '@${widget.user.username}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14.sp,
              fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
            ),
          ),
        ],
        if (widget.user.bio.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            widget.user.bio,
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withValues(alpha: 0.8), fontSize: 14.sp),
          ),
        ],
        if (widget.user.instagramHandle.isNotEmpty || widget.user.twitterHandle.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.user.instagramHandle.isNotEmpty)
                _SocialIconButton(
                  icon: Icons.link,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: () => launchUrl(
                    Uri.parse('https://instagram.com/${widget.user.instagramHandle}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              if (widget.user.instagramHandle.isNotEmpty && widget.user.twitterHandle.isNotEmpty)
                SizedBox(width: 12.w),
              if (widget.user.twitterHandle.isNotEmpty)
                _SocialIconButton(
                  icon: Icons.link,
                  label: 'X / Twitter',
                  color: const Color(0xFF1DA1F2),
                  onTap: () => launchUrl(
                    Uri.parse('https://x.com/${widget.user.twitterHandle}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
        ],
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: titleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place, color: Colors.amber, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                "$trueVisitedCount Places Visited",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Achievements',
            style: TextStyle(color: titleColor, fontSize: 20.sp, fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'], fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 16.h),
        Builder(
          builder: (context) {
            final displayBadges = BadgeConstants.allBadges.where((b) {
              return !b.isSecret || widget.user.visitedLandmarks.contains(b.id);
            }).toList();

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.w,
              runSpacing: 16.h,
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
        SizedBox(height: 16.h),
        _UniversalInfoStrip(guide: widget.user),
        SizedBox(height: 24.h),
        Text(
          'About Me',
          style: TextStyle(color: titleColor, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo']),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.user.bio.isNotEmpty
            ? widget.user.bio
            : 'This guide has not provided a bio yet. Contact them to learn more about their experiences and offerings.',
          maxLines: _expandedBio ? null : 4,
          overflow: _expandedBio ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            fontSize: 14.sp,
            height: 1.4,
          ),
        ),
        if (widget.user.bio.length > 100)
          GestureDetector(
            onTap: () => setState(() => _expandedBio = !_expandedBio),
            child: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                _expandedBio ? 'View less' : 'View more',
                style: TextStyle(color: titleColor, fontSize: 13.sp, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            ),
          ),
        if (widget.user.instagramHandle.isNotEmpty || widget.user.twitterHandle.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              if (widget.user.instagramHandle.isNotEmpty)
                _SocialIconButton(
                  icon: Icons.link,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: () => launchUrl(
                    Uri.parse('https://instagram.com/${widget.user.instagramHandle}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              if (widget.user.instagramHandle.isNotEmpty && widget.user.twitterHandle.isNotEmpty)
                SizedBox(width: 12.w),
              if (widget.user.twitterHandle.isNotEmpty)
                _SocialIconButton(
                  icon: Icons.link,
                  label: 'X / Twitter',
                  color: const Color(0xFF1DA1F2),
                  onTap: () => launchUrl(
                    Uri.parse('https://x.com/${widget.user.twitterHandle}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
        ],
        SizedBox(height: 24.h),
        Text(
          'Hosted Tours',
          style: TextStyle(color: titleColor, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo']),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 400.h,
          child: _UniversalGuideToursList(guideId: widget.user.id),
        ),
        // Reviews section
        if (widget.user.reviewCount > 0) ...[
          SizedBox(height: 24.h),
          Text(
            'Traveler Reviews',
            style: TextStyle(color: titleColor, fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo']),
          ),
          SizedBox(height: 12.h),
          _UniversalGuideReviews(guideId: widget.user.id),
        ],
        if (FirebaseAuth.instance.currentUser?.uid == widget.user.id) ...[
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: titleColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreenEnhanced()));
              },
              child: Text('Edit Profile', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
          width: 50.r,
          height: 50.r,
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
              ? Icon(badge.iconData, color: Colors.amber, size: 24.r)
              : Icon(Icons.lock, color: Colors.grey, size: 20.r),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: 70.w,
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
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: titleColor.withValues(alpha: 0.3), width: 2),
                color: isDark ? const Color(0xFF3E2C1E) : const Color(0xFF7A4B1D),
              ),
              child: ShimmerImage(
                url: guide.profileImageUrl,
                width: 90.r,
                height: 90.r,
                borderRadius: BorderRadius.circular(16.r),
                fallbackIcon: Icons.person,
                fallbackBackgroundColor: isDark ? const Color(0xFF3E2C1E) : const Color(0xFF7A4B1D),
                fallbackIconColor: Colors.white70,
                fallbackIconSize: 50.r,
              ),
            ),
            Positioned(
              top: 4.h,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(color: isDark ? Colors.black54 : Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.verified, color: Colors.blue, size: 14.r),
              ),
            ),
          ],
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${guide.firstName} ${guide.lastName}'.trim(),
                style: TextStyle(fontSize: 24.sp, color: titleColor, fontWeight: FontWeight.bold, height: 1.1),
              ),
              if (guide.username.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  '@${guide.username}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13.sp,
                    fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              if (guide.reviewCount == 0)
                Text("New Guide", style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.w600))
              else
                Row(
                  children: [
                    Text('${guide.rating.toStringAsFixed(1)} ', style: TextStyle(color: titleColor, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                    Icon(Icons.star, color: Colors.amber, size: 18.r),
                    Text(' (${guide.reviewCount} reviews)', style: TextStyle(color: titleColor.withValues(alpha: 0.7), fontSize: 13.sp)),
                  ],
                ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16.r, color: titleColor.withValues(alpha: 0.8)),
                  SizedBox(width: 4.w),
                  Text(
                    guide.nationality.isNotEmpty ? guide.nationality : 'Egypt',
                    style: TextStyle(fontSize: 14.sp, color: titleColor.withValues(alpha: 0.8)),
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
    final borderColor = isDark ? AppColors.darkText.withValues(alpha: 0.18) : const Color(0xFFBDA47D);
    final titleColor = isDark ? AppColors.darkText : const Color(0xFF7A4B1D);
    final subColor = isDark ? AppColors.darkText.withValues(alpha: 0.6) : const Color(0xFFB6A17F);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildInfoItem(Icons.language, guide.certifiedLanguages.isNotEmpty ? guide.certifiedLanguages.join(', ') : 'EN/AR', 'Languages', titleColor, subColor)),
          Container(width: 1, height: 40.h, color: borderColor),
          Expanded(child: _buildInfoItem(Icons.verified_user, 'Licensed', 'Status', titleColor, subColor)),
          Container(width: 1, height: 40.h, color: borderColor),
          Expanded(child: _buildInfoItem(Icons.star_half_rounded, guide.reviewCount == 0 ? 'New' : guide.rating.toStringAsFixed(1), 'Rating', titleColor, subColor)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle, Color titleColor, Color subColor) {
    return Column(
      children: [
        Icon(icon, color: titleColor.withValues(alpha: 0.8), size: 24.r),
        SizedBox(height: 4.h),
        Text(title, style: TextStyle(color: titleColor, fontSize: 13.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(subtitle, style: TextStyle(color: subColor, fontSize: 11.sp)),
      ],
    );
  }
}

class _UniversalGuideReviews extends StatefulWidget {
  final String guideId;
  const _UniversalGuideReviews({required this.guideId});

  @override
  State<_UniversalGuideReviews> createState() => _UniversalGuideReviewsState();
}

class _UniversalGuideReviewsState extends State<_UniversalGuideReviews> {
  static const int _pageSize = 3;
  int _limit = _pageSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('guideId', isEqualTo: widget.guideId)
          .orderBy('createdAt', descending: true)
          .limit(_limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final hasMore = docs.length == _limit;

        return Column(
          children: [
            ...docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final rating = (d['rating'] as num?)?.toDouble() ?? 0;
            final text = (d['text'] ?? d['comment'] ?? '') as String;
            final userName = (d['userName'] ?? 'Traveler') as String;
            final userImage = d['userImage'] as String?;
            final createdAt = (d['createdAt'] as Timestamp?)?.toDate();

            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerAvatar(
                    url: userImage,
                    radius: 18.r,
                    iconSize: 18.r,
                    fallbackBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(userName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 12.r,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (text.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(text,
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
                        ],
                        if (createdAt != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
            }),
            if (hasMore)
              TextButton.icon(
                onPressed: () => setState(() => _limit += _pageSize),
                icon: Icon(Icons.expand_more, size: 18.r),
                label: const Text('Show more reviews'),
              ),
          ],
        );
      },
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
                separatorBuilder: (_, _) => SizedBox(width: 16.w),
                itemBuilder: (context, index) {
                  return SizedBox(width: 250.w, child: TourCard(tour: tours[index]));
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

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16.r),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
