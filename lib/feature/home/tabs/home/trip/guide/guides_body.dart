import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/guide/widget/guide_card.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/guide/widget/guide_trip_type_tab.dart';
import 'package:lost_in_egypt/theme/theme.dart';
import '../../../navigator/widget/account_menu_button.dart';
import '../../../navigator/widget/search_header.dart';
import 'guide_details_screen.dart';
import '../../../../../tours/presentation/widgets/tour_card.dart';
import '../../../../../tours/domain/repositories/tours_repository.dart';
import '../../../../../tours/domain/entities/tour_entity.dart';
import '../../../../../../../core/di/service_locator.dart';
import '../../../../../auth/data/models/user.dart';

class GuideBodyScreen extends StatefulWidget {
  const GuideBodyScreen({super.key});

  @override
  State<GuideBodyScreen> createState() => _GuideBodyScreenState();
}

class _GuideBodyScreenState extends State<GuideBodyScreen> {
  String? _profileImageUrl;
  int _tabIndex = 0; // 0 for Tours, 1 for Guides

  late Stream<List<TourEntity>> _toursStream;
  late Stream<QuerySnapshot> _guidesStream;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _toursStream = sl<ToursRepository>().getToursStream();
    _guidesStream = FirebaseFirestore.instance
        .collection('users')
        .where('isVerifiedGuide', isEqualTo: true)
        .snapshots();
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
    final bool isDark = theme.brightness == Brightness.dark;

    // ✅ Your palette-driven background behavior
    final Color baseBg =
    isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final Color overlayColor =
    isDark ? AppColors.darkPatternOverlay : AppColors.lightPatternOverlay;

    // ✅ Tune these if you want stronger/weaker texture
    final double patternOpacity = isDark ? 0.7 : 0.5;
    final double overlayOpacity = isDark ? 0.85 : 0.40;

    return Scaffold(
      backgroundColor: baseBg,
      body: Stack(
        children: [
          // Base background color
          Positioned.fill(
            child: Container(color: baseBg),
          ),

          // Pattern image with theme-aware opacity
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                'assets/pattern_comp.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Color overlay using your AppColors
          Positioned.fill(
            child: Container(
              color: overlayColor.withOpacity(overlayOpacity),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: isDark
                              ? AppColors.darkText
                              : const Color(0xFF7A4B1D),
                        ),
                      ),
                      Expanded(
                        child: SearchHeader(
                          profileImageUrl: _profileImageUrl,
                          onSignOut: _handleSignOut,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AccountMenuButton(
                        profileImageUrl: _profileImageUrl,
                        onSignOut: _handleSignOut,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.white.withOpacity(0.02)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 0),
                            child: GuideTripTypeTab(title: 'Tours', selected: _tabIndex == 0),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 1),
                            child: GuideTripTypeTab(title: 'Guides', selected: _tabIndex == 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: _tabIndex == 0 ? _buildToursList() : _buildGuidesList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToursList() {
    return StreamBuilder<List<TourEntity>>(
      stream: _toursStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading tours.'));
        }
        final tours = snapshot.data ?? [];
        if (tours.isEmpty) {
          return const Center(child: Text('No tours available.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          itemBuilder: (context, index) {
            final tour = tours[index];
            return TourCard(tour: tour);
          },
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemCount: tours.length,
        );
      },
    );
  }

  Widget _buildGuidesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _guidesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading guides.'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No guides available.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final user = UserModel.fromMap(data, docs[index].id);
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuideDetailsScreen(guide: user),
                  ),
                );
              },
              child: GuideCard(guide: user),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemCount: docs.length,
        );
      },
    );
  }
}