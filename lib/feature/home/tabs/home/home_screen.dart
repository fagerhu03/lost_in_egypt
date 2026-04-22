import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/guide/guides_body.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/solo_trip_page.dart';
import '../../../../theme/theme.dart';
import '../navigator/widget/account_menu_button.dart';
import '../navigator/widget/search_header.dart';
import './data/datasources/local_mock_data.dart';
import './data/models/map_item_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profileImageUrl;
  late Stream<QuerySnapshot> _eventsStream;

  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentHeroIndex = 0;

  final List<String> _heroImages = [
    "assets/images/home_bridge.png",
    "assets/images/home_bridge.png",
    "assets/images/home_bridge.png",
  ];

  @override
  void initState() {
    super.initState();

    _eventsStream =
        FirebaseFirestore.instance.collection('events').limit(5).snapshots();

    _fetchUserProfile();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients || _heroImages.isEmpty) return;

      int nextPage = _currentHeroIndex + 1;
      if (nextPage >= _heroImages.length) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
        debugPrint("Error fetching profile: $e");
      }
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

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final primary = isDark ? AppColors.darkNavBar : theme.colorScheme.primary;

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = textColor.withOpacity(0.65);

    final cardShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.10),
      blurRadius: 14,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    );

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _heroImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentHeroIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _heroImages[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Container(
                  height: 260,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.08),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: SearchHeader(onSignOut: () {})),
                      const SizedBox(width: 12),
                      AccountMenuButton(
                        profileImageUrl: _profileImageUrl,
                        onSignOut: _handleSignOut,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 50, end: 50),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_heroImages.length, (index) {
                    final bool isActive = index == _currentHeroIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isActive ? 22 : 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? primary
                            : primary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Where do you want to go?",
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontSize: 22,
                  fontFamily: "Marcellus",
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...LocalMockData.categories.map((category) {
                    return _categoryCard(
                      icon: category.iconPath,
                      title: category.title,
                      surface: surface,
                      textColor: textColor,
                      shadow: cardShadow,
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Events",
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: 22,
                      fontFamily: "Marcellus",
                    ),
                  ),
                  Text(
                    "see all >",
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Marcellus",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: StreamBuilder<QuerySnapshot>(
                stream: _eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Something went wrong",
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No events found",
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final event = EventModel.fromMap(data, docs[index].id);

                      return _eventCard(
                        title: event.title,
                        imagePath: event.imagePath,
                        surface: surface,
                        textColor: textColor,
                        shadow: cardShadow,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Plan your trip",
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Marcellus",
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _tripCard(
                      title: "Guides",
                      surface: surface,
                      textColor: textColor,
                      shadow: cardShadow,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GuideBodyScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tripCard(
                      title: "Solo trip",
                      surface: surface,
                      textColor: textColor,
                      shadow: cardShadow,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SoloTripPage(profileImageUrl: _profileImageUrl, onSignOut: _handleSignOut,),),


                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard({
    required String icon,
    required String title,
    required Color surface,
    required Color textColor,
    required BoxShadow shadow,
    required bool isDark,
  }) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [shadow],
        border: Border.all(
          color:
          (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black)
              .withOpacity(0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                icon,
                width: 40,
                color: isDark
                    ? AppColors.darkNavBar
                    : Theme.of(context).colorScheme.primary,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontFamily: "Marcellus",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard({
    required String title,
    required String imagePath,
    required Color surface,
    required Color textColor,
    required BoxShadow shadow,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [shadow],
        border: Border.all(
          color:
          (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black)
              .withOpacity(0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 117,
                      width: double.infinity,
                      child: imagePath.startsWith('http')
                          ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.white.withOpacity(0.35),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () {},
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.favorite_border,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: "Marcellus",
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripCard({
    required String title,
    required Color surface,
    required Color textColor,
    required BoxShadow shadow,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 145,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [shadow],
        border: Border.all(
          color:
          (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black)
              .withOpacity(0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                title == "Guides"
                    ? "assets/icons/guide.png"
                    : "assets/icons/solo_trip.png",
                width: 80,
                color: isDark
                    ? AppColors.darkNavBar.withOpacity(0.9)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.7),
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Marcellus",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}