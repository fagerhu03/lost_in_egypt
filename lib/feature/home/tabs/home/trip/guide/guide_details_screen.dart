import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
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
        ? AppColors.darkText.withOpacity(0.18)
        : const Color(0xFFBDA47D);

    final double patternOpacity = isDark ? 0.6 : 0.6;

    final btnBg = isDark
        ? AppColors.darkPrimaryButton
        : AppColors.lightPrimaryButton;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
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
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: titleColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Guide Details',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 18,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBox.withOpacity(0.75)
                              : Colors.white.withOpacity(0.75),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          border: Border.all(color: frameColor, width: 1),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GuideHeaderCard(guide: widget.guide),
                            const SizedBox(height: 12),
                            _InfoStrip(guide: widget.guide),
                            const SizedBox(height: 20),
                            Text(
                              'Brief Trip',
                              style: TextStyle(color: titleColor, fontSize: 24),
                            ),
                            const SizedBox(height: 6),
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
                                    ? AppColors.darkText.withOpacity(0.85)
                                    : const Color(0xFF3F3A35),
                                fontSize: 12,
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
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Hosted Tours',
                              style: TextStyle(color: titleColor, fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 320,
                              child: _GuideToursList(guideId: widget.guide.id ?? ''),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 30 ),
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
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF3E2C1E), Color(0xFF2A2119)]
                        : const [Color(0xFF7A4B1D), Color(0xFF4B3021)],
                  ),
                  image: guide.profileImageUrl.isNotEmpty 
                      ? DecorationImage(
                          image: NetworkImage(guide.profileImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: guide.profileImageUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFFEDE9D9),
                        size: 52,
                      )
                    : null,
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red.shade300,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${guide.firstName} ${guide.lastName}'.trim(),
                  style: TextStyle(
                    fontSize: 24,
                    color: titleColor,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 4),
                if (guide.reviewCount == 0)
                  Text("New Guide", style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600))
                else 
                  Row(
                    children: [
                      Text('${guide.rating.toStringAsFixed(1)} ', style: TextStyle(color: titleColor, fontSize: 16)),
                      const Icon(Icons.star, color: Colors.amber, size: 19),
                      Text(' (${guide.reviewCount})', style: TextStyle(color: titleColor.withOpacity(0.7), fontSize: 14)),
                    ],
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: titleColor),
                    const SizedBox(width: 2),
                    Text(
                      guide.nationality.isNotEmpty ? guide.nationality : 'Egypt',
                      style: TextStyle(
                        fontSize: 16,
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
      fontSize: 16,
      height: 0.95,
    );

    final itemSubStyle = TextStyle(
      color: isDark
          ? AppColors.darkText.withOpacity(0.6)
          : const Color(0xFFB6A17F),
      fontSize: 12,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? AppColors.darkText.withOpacity(0.18)
              : const Color(0xFFBDA47D),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(18),
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
      height: 38,
      color: isDark
          ? AppColors.darkText.withOpacity(0.18)
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
              ? AppColors.darkText.withOpacity(0.8)
              : const Color(0xFF9B7A4D),
          size: 24,
        ),
        const SizedBox(height: 2),
        Text(title, style: titleStyle),
        Text(subtitle, style: subtitleStyle),
      ],
    );
  }
}

class _PhotosRow extends StatefulWidget {
  final bool isDark;

  const _PhotosRow({super.key, required this.isDark});

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
        ? AppColors.darkText.withOpacity(0.9)
        : const Color(0xFF7A4B1D);

    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 44),
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  photos[index],
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: _scrollLeft,
              icon: Icon(Icons.chevron_left, size: 34, color: arrowColor),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _scrollRight,
              icon: Icon(Icons.chevron_right, size: 34, color: arrowColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideToursList extends StatefulWidget {
  final String guideId;

  const _GuideToursList({super.key, required this.guideId});

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
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 250,
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
