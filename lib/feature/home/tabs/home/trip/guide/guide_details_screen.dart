import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lost_in_egypt/theme/theme.dart';
import '../../../navigator/widget/account_menu_button.dart';
import 'data/guide_model.dart';

class GuideDetailsScreen extends StatefulWidget {
  final GuideModel guide;

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
                            _InfoStrip(price: widget.guide.price),
                            const SizedBox(height: 20),
                            Text(
                              'Brief Trip',
                              style: TextStyle(color: titleColor, fontSize: 24),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This resort presents itself as a tranquil yet upscale getaway, set within the '
                              'scenic landscape of the Faiyum region. The architecture and landscaping '
                              'suggest a design that blends leisure luxury with the surrounding natural '
                              'environment, think spacious grounds, open-pool areas, and resort buildings '
                              'that feel relaxed yet refined. '
                              'Guests can enjoy guided tours, sunset views, cultural storytelling sessions, '
                              'and personalized experiences tailored to their interests.',
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
                              'Photos',
                              style: TextStyle(color: titleColor, fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            _PhotosRow(isDark: isDark),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
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
                                  'Book Now',
                                  style: TextStyle(
                                    fontSize: 24,
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
}

class _GuideHeaderCard extends StatelessWidget {
  final GuideModel guide;

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
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFEDE9D9),
                  size: 52,
                ),
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
                  guide.name,
                  style: TextStyle(
                    fontSize: 24,
                    color: titleColor,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      color: i < guide.rating
                          ? (isDark
                                ? AppColors.darkPrimaryButton
                                : AppColors.lightPrimaryButton)
                          : (isDark ? Colors.white38 : const Color(0xFFBDBDBD)),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: titleColor),
                    const SizedBox(width: 2),
                    Text(
                      guide.location,
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
  final String price;

  const _InfoStrip({required this.price});

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
              icon: Icons.location_on_outlined,
              title: 'Pyramids',
              subtitle: 'Location',
              titleStyle: itemTitleStyle,
              subtitleStyle: itemSubStyle,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _InfoItem(
              icon: Icons.payments_outlined,
              title: price,
              subtitle: 'Price',
              titleStyle: itemTitleStyle,
              subtitleStyle: itemSubStyle,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _InfoItem(
              icon: Icons.access_time_outlined,
              title: '2 hours',
              subtitle: 'Duration',
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
