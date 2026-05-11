import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/guide/guides_body.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/solo_trip_page.dart';
import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import 'package:lost_in_egypt/feature/tours/presentation/pages/tour_detail_screen.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';
import '../../../../theme/theme.dart';
import '../navigator/widget/account_menu_button.dart';
import './data/datasources/local_mock_data.dart';
import './data/datasources/local_places_service.dart';
import './data/models/map_item_models.dart';
import './presentation/category_places_screen.dart';
import './presentation/all_events_screen.dart';
import './presentation/place_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profileImageUrl;
  String? _firstName;
  late Future<QuerySnapshot> _eventsFuture;
  List<PlaceModel> _popularPlaces = [];

  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentHeroIndex = 0;

  final List<String> _heroImages = [
    "assets/images/event1.jpg",
    "assets/images/event3.jpg",
    "assets/images/home_bridge.png",
  ];

  @override
  void initState() {
    super.initState();

    _eventsFuture =
        FirebaseFirestore.instance.collection('events').orderBy('date').limit(5).get();

    _fetchUserProfile();
    _loadPopularPlaces();
    _startAutoSlide();
  }

  Future<void> _loadPopularPlaces() async {
    final places = await LocalPlacesService.getTopRatedPlaces(limit: 20);
    places.shuffle();
    if (mounted) setState(() => _popularPlaces = places.take(10).toList());
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
            _firstName = doc.data()?['firstName'];
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
                      const Spacer(),
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
            // ── Greeting ──
            if (_firstName != null && _firstName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "${_greetingForTimeOfDay()}, $_firstName 👋",
                  style: TextStyle(
                    color: primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Marcellus",
                  ),
                ),
              ),
            const SizedBox(height: 8),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryPlacesScreen(
                              categoryId: category.id,
                              categoryTitle: category.title,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 25),
            // ── Popular Places ──
            if (_popularPlaces.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Popular Places",
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                        fontSize: 22,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: _popularPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _popularPlaces[index];
                    return _popularPlaceCard(
                      place: place,
                      primary: primary,
                      textColor: textColor,
                      shadow: cardShadow,
                      isDark: isDark,
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
            ],
            // ── Events ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Events",
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 22,
                          fontFamily: "Marcellus",
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllEventsScreen()),
                      );
                    },
                    child: Text(
                      "see all >",
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: FutureBuilder<QuerySnapshot>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No events at the moment",
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
                      // Firestore schema stores images as a list; fall back to first item
                      final imageUrl = event.imagePath.isNotEmpty
                          ? event.imagePath
                          : ((data['images'] as List?)?.firstOrNull?.toString() ?? '');

                      return _eventCard(
                        title: event.title,
                        imagePath: imageUrl,
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
            // ── Popular Tours ──
            _popularToursSection(
              primary: primary,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surface: surface,
              cardShadow: cardShadow,
              isDark: isDark,
            ),
            // ── Plan your trip ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Plan your trip",
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Marcellus",
                    ),
                  ),
                ],
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
    required VoidCallback onTap,
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
          onTap: onTap,
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

  String _greetingForTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  Widget _popularPlaceCard({
    required PlaceModel place,
    required Color primary,
    required Color textColor,
    required BoxShadow shadow,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [shadow],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            place.imagePath.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: place.imagePath,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: primary.withOpacity(0.08),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: primary.withOpacity(0.06),
                      child: Icon(Icons.image_not_supported_outlined,
                          color: primary.withOpacity(0.3), size: 32),
                    ),
                  )
                : Image.asset(place.imagePath, fit: BoxFit.cover),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Rating pill
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title + City
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Marcellus",
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.locationAddress.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 11, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place.locationAddress,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularToursSection({
    required Color primary,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surface,
    required BoxShadow cardShadow,
    required bool isDark,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tours')
          .where('isArchived', isEqualTo: false)
          .orderBy('rating', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Popular Tours",
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: 22,
                      fontFamily: "Marcellus",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final tour = TourEntity(
                    id: docs[index].id,
                    guideId: data['guideId'] ?? '',
                    title: data['title'] ?? '',
                    description: data['description'] ?? '',
                    destinations: (data['destinations'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    price: (data['price'] ?? 0).toDouble(),
                    meetingLatitude: (data['meetingLatitude'] ?? 30.0444).toDouble(),
                    meetingLongitude: (data['meetingLongitude'] ?? 31.2357).toDouble(),
                    meetingTime: (data['meetingTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    frequency: data['frequency'] ?? '',
                    meetingLocationName: data['meetingLocationName'] ?? '',
                    images: (data['images'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    maxAttendees: (data['maxAttendees'] ?? 10).toInt(),
                    rating: (data['rating'] ?? 0).toDouble(),
                    reviewCount: (data['reviewCount'] ?? 0).toInt(),
                    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  );

                  final hasImage = tour.images.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
                      );
                    },
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [cardShadow],
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tour image
                          SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: hasImage
                                ? CachedNetworkImage(
                                    imageUrl: tour.images.first,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: primary.withOpacity(0.08),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: primary.withOpacity(0.06),
                                      child: Icon(Icons.tour, color: primary.withOpacity(0.3)),
                                    ),
                                  )
                                : Container(
                                    color: primary.withOpacity(0.06),
                                    child: Icon(Icons.tour, color: primary.withOpacity(0.3), size: 40),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tour.title,
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Marcellus",
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (tour.rating > 0) ...[
                                      Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                                      const SizedBox(width: 2),
                                      Text(
                                        tour.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    ValueListenableBuilder<String>(
                                      valueListenable: CurrencyController.currency,
                                      builder: (context, currency, _) {
                                        return FutureBuilder<double>(
                                          future: CurrencyService.instance
                                              .convertFromEGP(tour.price, currency),
                                          builder: (_, snap) {
                                            final label = snap.hasData
                                                ? CurrencyService.format(snap.data!, currency)
                                                : 'EGP ${tour.price.toStringAsFixed(0)}';
                                            return Text(
                                              label,
                                              style: TextStyle(
                                                color: primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
          ],
        );
      },
    );
  }
}