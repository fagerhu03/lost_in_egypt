import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/presentation/edit_profile_screen_enhanced.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_constants.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_model.dart';
import 'package:lost_in_egypt/feature/admin/presentation/pages/admin_dashboard_screen.dart' as lost_in_egypt_admin;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/tours/presentation/bloc/guide_tours_cubit.dart' as lost_in_egypt_tours;
import 'package:lost_in_egypt/feature/tours/presentation/pages/guide_dashboard_screen.dart' as lost_in_egypt_tours;
import 'package:lost_in_egypt/feature/guide_application/presentation/bloc/apply_guide_cubit.dart' as lost_in_egypt_guide_cubit;
import 'package:lost_in_egypt/feature/guide_application/presentation/pages/apply_guide_screen.dart' as lost_in_egypt_guide_screen;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        setState(() {
          _user = UserModel.fromMap(doc.data()!, doc.id);
          _isLoading = false;
        });
      } else {
         setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    final patternOpacity = isDark ? 0.20 : 0.40;

    final tileShadow = BoxShadow(
      color: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.black.withValues(alpha: 0.04), // soft shadow
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    );

    final borderColor =
    (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.10 : 0.06);

    final User? authUser = FirebaseAuth.instance.currentUser;
    String displayName = "User";
    if (_user != null) {
        displayName = "${_user!.firstName} ${_user!.lastName}".trim();
        if (displayName.isEmpty) displayName = "User";
    } else if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) {
        displayName = authUser.displayName!;
    }

    final String profileUrl = _user?.profileImageUrl ?? "";

    // The beige card color from prototype
    final Color cardColor = isDark ? surface.withValues(alpha: 0.5) : const Color(0xFFF3F2E4);
    // Gold button color from prototype
    final Color goldButtonColor = const Color(0xFFC79A00);

    int trueVisitedCount = 0;
    if (_user != null) {
      final secretBadgeIds = BadgeConstants.allBadges.where((b) => b.isSecret).map((b) => b.id).toList();
      trueVisitedCount = _user!.visitedLandmarks.where((id) => !secretBadgeIds.contains(id)).length;
    }

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
                // Top Custom App Bar matching prototype
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new, color: onSurface, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Where want to go?",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.account_circle, color: onSurface.withValues(alpha: 0.6), size: 36),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                  : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Card
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
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                      color: isDark ? onSurface : const Color(0xFF6B3A28), // Brown text from prototype
                                      fontSize: 22,
                                      fontFamily: "Marcellus",
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // --- GAMIFICATION UI HERE ---
                                  if (_user != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.6),
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
                                              color: onSurface.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Badges
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Builder(
                                        builder: (context) {
                                          final displayBadges = BadgeConstants.allBadges.where((b) {
                                            return !b.isSecret || _user!.visitedLandmarks.contains(b.id);
                                          }).toList();
                                          
                                          return Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 6,
                                            runSpacing: 10,
                                            children: List.generate(
                                              displayBadges.length,
                                              (index) {
                                                final badge = displayBadges[index];
                                                final isUnlocked = _user!.visitedLandmarks.contains(badge.id) || 
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
                                ],
                              ),
                            ),
                            
                            // Profile Avatar Overlapping
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: surface,
                                border: Border.all(color: cardColor, width: 4),
                                image: profileUrl.isNotEmpty 
                                  ? DecorationImage(
                                      image: NetworkImage(profileUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              ),
                              child: profileUrl.isEmpty
                                  ? Icon(Icons.person, size: 60, color: onSurface.withValues(alpha: 0.5))
                                  : null,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        Text(
                          "Account Settings:",
                          style: TextStyle(
                            color: isDark ? onSurface : const Color(0xFF6B3A28), // Matches prototype
                            fontSize: 16,
                            fontFamily: "Marcellus",
                          ),
                        ),
                        const SizedBox(height: 16),

                        _AccountTile(
                          title: "Edit Profile",
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const EditProfileScreenEnhanced(),
                              ),
                            );
                            _loadUser();
                          },
                          surface: surface,
                          onSurface: onSurface,
                          borderColor: borderColor,
                          shadow: tileShadow,
                        ),


                        if (_user?.role == 'tourist' && _user?.applicationStatus != 'pending') ...[
                          _AccountTile(
                            title: "Apply to be a Guide",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider(
                                    create: (context) => lost_in_egypt_guide_cubit.ApplyGuideCubit(
                                      applyGuideUseCase: GetIt.I(),
                                    ),
                                    child: const lost_in_egypt_guide_screen.ApplyGuideScreen(),
                                  ),
                                ),
                              );
                            },
                            surface: surface,
                            onSurface: onSurface,
                            borderColor: borderColor,
                            shadow: tileShadow,
                          ),
                        ],
                        _AccountTile(
                          title: "Cards Detail",
                          onTap: () {},
                          surface: surface,
                          onSurface: onSurface,
                          borderColor: borderColor,
                          shadow: tileShadow,
                        ),
                        _AccountTile(
                          title: "Registered tours",
                          onTap: () {},
                          surface: surface,
                          onSurface: onSurface,
                          borderColor: borderColor,
                          shadow: tileShadow,
                        ),
                        _AccountTile(
                          title: "Your plan",
                          onTap: () {},
                          surface: surface,
                          onSurface: onSurface,
                          borderColor: borderColor,
                          shadow: tileShadow,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sign out button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _handleSignOut(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldButtonColor,
                              foregroundColor: Colors.black87, // Dark text on gold
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Sign out",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
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
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border.all(
              color: isUnlocked ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: isUnlocked
              ? Icon(badge.iconData, color: Colors.amber, size: 22)
              : const Icon(Icons.lock, color: Colors.grey, size: 18),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64, // Keep names from spreading too wide and forcing wraps
          child: Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              color: isUnlocked ? onSurface : onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  // themed
  final Color surface;
  final Color onSurface;
  final Color borderColor;
  final BoxShadow shadow;

  const _AccountTile({
    required this.title,
    required this.onTap,
    required this.surface,
    required this.onSurface,
    required this.borderColor,
    required this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [shadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.85),
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}