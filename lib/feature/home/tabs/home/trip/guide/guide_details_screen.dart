import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/theme/theme.dart';
import '../../../navigator/widget/account_menu_button.dart';
import '../../../../../auth/data/models/user.dart';
import '../../../../../../core/di/service_locator.dart';
import '../../../../../tours/presentation/widgets/tour_card.dart';
import '../../../../../tours/domain/repositories/tours_repository.dart';
import '../../../../../tours/domain/entities/tour_entity.dart';
import '../../../account/presentation/edit_profile_screen_enhanced.dart';

class GuideDetailsScreen extends StatefulWidget {
  final UserModel guide;

  const GuideDetailsScreen({super.key, required this.guide});

  @override
  State<GuideDetailsScreen> createState() => _GuideDetailsScreenState();
}

class _GuideDetailsScreenState extends State<GuideDetailsScreen> {
  String? _profileImageUrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark ? AppColors.darkText : const Color(0xFF7A4B1D);

    final frameColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.18)
        : const Color(0xFFBDA47D);

    final double patternOpacity = isDark ? 0.6 : 0.6;

    final btnBg = isDark
        ? AppColors.darkPrimaryButton
        : AppColors.lightPrimaryButton;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFFFFEF0),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/pattern_comp.png'),
                fit: BoxFit.cover,
                opacity: patternOpacity,
              ),
            ),
            child: SafeArea(
              bottom: false, // ✅ no bottom gap
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 12.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: titleColor,
                            size: 30.r,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Guide Details',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        AccountMenuButton(
                          profileImageUrl: _profileImageUrl,
                          onSignOut: _handleSignOut,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBox.withValues(alpha: 0.75)
                              : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15.r),
                            topRight: Radius.circular(15.r),
                          ),
                          border: Border.all(color: frameColor, width: 1),
                        ),
                        padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GuideHeaderCard(guide: widget.guide),
                            SizedBox(height: 12.h),
                            _InfoStrip(guide: widget.guide),
                            SizedBox(height: 20.h),
                            Text(
                              'Brief Trip',
                              style: TextStyle(color: titleColor, fontSize: 24.sp),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.guide.bio.isNotEmpty
                                ? widget.guide.bio
                                : 'This guide has not provided a bio yet. Contact them to learn more about their experiences and offerings.',
                              maxLines: _expanded ? null : 4,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkText.withValues(alpha: 0.85)
                                    : const Color(0xFF3F3A35),
                                fontSize: 12.sp,
                                height: 1.35,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _expanded = !_expanded;
                                });
                              },
                              child: Text(
                                _expanded ? 'View less' : 'View more',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 12.sp,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 18.h),
                            Text(
                              'Hosted Tours',
                              style: TextStyle(color: titleColor, fontSize: 24.sp),
                            ),
                            SizedBox(height: 10.h),
                            SizedBox(
                              height: 320.h,
                              child: _GuideToursList(guideId: widget.guide.id),
                            ),
                            const Spacer(),
                            if (FirebaseAuth.instance.currentUser?.uid == widget.guide.id)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreenEnhanced(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: btnBg,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 30.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _showEditProfileSheet as we now use EditProfileScreenEnhanced

}

class _GuideHeaderCard extends StatelessWidget {
  final UserModel guide;

  const _GuideHeaderCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.darkText : const Color(0xFF7A4B1D);

    return Padding(
      padding: EdgeInsets.all(10.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ShimmerImage(
                url: guide.profileImageUrl,
                width: 84.r,
                height: 84.r,
                borderRadius: BorderRadius.circular(14.r),
                fit: BoxFit.cover,
                fallbackIcon: Icons.person,
                fallbackBackgroundColor: isDark
                    ? const Color(0xFF3E2C1E)
                    : const Color(0xFF7A4B1D),
                fallbackIconColor: const Color(0xFFEDE9D9),
                fallbackIconSize: 52.r,
              ),
              PositionedDirectional(
                top: 4.h,
                end: 4.w,
                child: Container(
                  width: 18.r,
                  height: 18.r,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red.shade300,
                    size: 12.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${guide.firstName} ${guide.lastName}'.trim(),
                  style: TextStyle(
                    fontSize: 24.sp,
                    color: titleColor,
                    height: 0.95,
                  ),
                ),
                SizedBox(height: 4.h),
                if (guide.reviewCount == 0)
                  Text("New Guide", style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.w600))
                else
                  Row(
                    children: [
                      Text('${guide.rating.toStringAsFixed(1)} ', style: TextStyle(color: titleColor, fontSize: 16.sp)),
                      Icon(Icons.star, color: Colors.amber, size: 19.r),
                      Text(' (${guide.reviewCount})', style: TextStyle(color: titleColor.withValues(alpha: 0.7), fontSize: 14.sp)),
                    ],
                  ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16.r, color: titleColor),
                    SizedBox(width: 2.w),
                    Text(
                      guide.nationality.isNotEmpty ? guide.nationality : 'Egypt',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: titleColor,
                        height: 0.95,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final UserModel guide;

  const _InfoStrip({required this.guide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemTitleStyle = TextStyle(
      color: isDark ? AppColors.darkText : const Color(0xFF7A4B1D),
      fontSize: 16.sp,
      height: 0.95,
    );

    final itemSubStyle = TextStyle(
      color: isDark
          ? AppColors.darkText.withValues(alpha: 0.6)
          : const Color(0xFFB6A17F),
      fontSize: 12.sp,
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? AppColors.darkText.withValues(alpha: 0.18)
              : const Color(0xFFBDA47D),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              icon: Icons.language,
              title: guide.certifiedLanguages.isNotEmpty ? guide.certifiedLanguages.join(', ') : 'Arabic/English',
              subtitle: 'Languages',
              titleStyle: itemTitleStyle,
              subtitleStyle: itemSubStyle,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _InfoItem(
              icon: Icons.verified,
              title: 'Verified',
              subtitle: 'Status',
              titleStyle: itemTitleStyle,
              subtitleStyle: itemSubStyle,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _InfoItem(
              icon: Icons.star_border,
              title: guide.reviewCount == 0 ? 'New' : guide.rating.toStringAsFixed(1),
              subtitle: 'Rating',
              titleStyle: itemTitleStyle,
              subtitleStyle: itemSubStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 38.h,
      color: isDark
          ? AppColors.darkText.withValues(alpha: 0.18)
          : const Color(0xFFD0BEA2),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(
          icon,
          color: isDark
              ? AppColors.darkText.withValues(alpha: 0.8)
              : const Color(0xFF9B7A4D),
          size: 24.r,
        ),
        SizedBox(height: 2.h),
        Text(title, style: titleStyle),
        Text(subtitle, style: subtitleStyle),
      ],
    );
  }
}

class _PhotosRow extends StatefulWidget {
  final bool isDark;

  const _PhotosRow({required this.isDark});

  @override
  State<_PhotosRow> createState() => _PhotosRowState();
}

class _PhotosRowState extends State<_PhotosRow> {
  final ScrollController _controller = ScrollController();

  void _scrollLeft() {
    _controller.animateTo(
      _controller.offset - 240,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _controller.animateTo(
      _controller.offset + 240,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const photos = [
      'assets/images/event1.jpg',
      'assets/images/event2.jpg',
      'assets/images/event3.jpg',
      'assets/images/event4.jpg',
      'assets/images/event5.jpg',
      'assets/images/event6.jpg',
      'assets/images/event7.jpg',
    ];

    final arrowColor = widget.isDark
        ? AppColors.darkText.withValues(alpha: 0.9)
        : const Color(0xFF7A4B1D);

    return SizedBox(
      height: 120.h,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 44.w),
            itemCount: photos.length,
            separatorBuilder: (_, _) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image(
                  image: ResizeImage(AssetImage(photos[index]), width: 220),
                  width: 110.r,
                  height: 110.r,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: _scrollLeft,
              icon: Icon(Icons.chevron_left, size: 34.r, color: arrowColor),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _scrollRight,
              icon: Icon(Icons.chevron_right, size: 34.r, color: arrowColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideToursList extends StatefulWidget {
  final String guideId;

  const _GuideToursList({required this.guideId});

  @override
  State<_GuideToursList> createState() => _GuideToursListState();
}

class _GuideToursListState extends State<_GuideToursList> {
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
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final result = snapshot.data!;
          return result.fold(
            (failure) => Center(child: Text('Failed to load tours')),
            (tours) {
              if (tours.isEmpty) {
                return const Center(child: Text('No hosted tours yet.'));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tours.length,
                separatorBuilder: (_, _) => SizedBox(width: 16.w),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 250.w,
                    child: TourCard(tour: tours[index]),
                  );
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
