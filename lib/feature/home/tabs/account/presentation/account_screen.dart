import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_avatar.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/presentation/edit_profile_screen_enhanced.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_constants.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/feature/guide_application/presentation/bloc/apply_guide_cubit.dart' as lost_in_egypt_guide_cubit;
import 'package:lost_in_egypt/feature/guide_application/presentation/pages/apply_guide_screen.dart' as lost_in_egypt_guide_screen;
import 'package:lost_in_egypt/feature/tours/presentation/pages/booking_history_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/presentation/your_plan_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/community/presentation/saved_posts_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/my_plans_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserModel? _user;
  // Top 3 canonical taste keys (descending). Populated from the same user doc.
  List<String> _topTasteKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = sl<FirebaseAuth>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await sl<FirebaseFirestore>()
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Extract the top 3 strongest-positive taste keys for the "Your Taste"
        // card. Hidden when vector is empty or all zero/negative.
        final raw = data['tasteVector'];
        final topKeys = <String>[];
        if (raw is Map) {
          final entries = raw.entries
              .where((e) => (e.value is num) && (e.value as num).toDouble() > 0)
              .toList()
            ..sort((a, b) =>
                (b.value as num).toDouble().compareTo((a.value as num).toDouble()));
          for (final e in entries.take(3)) {
            topKeys.add(e.key.toString());
          }
        }
        setState(() {
          _user = UserModel.fromMap(data, doc.id);
          _topTasteKeys = topKeys;
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

  /// Converts a canonical taste-vector key (e.g. "historical_landmark",
  /// "pharaonic") into a human-readable label for the "Your Taste" pills.
  String _prettyTasteKey(String key) {
    const overrides = {
      'historical_landmark': 'History',
      'archaeological_site': 'Ancient Sites',
      'tourist_attraction': 'Attractions',
      'amusement_park': 'Theme Parks',
      'art_gallery': 'Art',
      'night_club': 'Nightlife',
      'shopping_mall': 'Shopping',
    };
    if (overrides.containsKey(key)) return overrides[key]!;
    return key
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _handleSignOut(BuildContext context) async {
    await sl<FirebaseAuth>().signOut();
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
          : Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    );

    final borderColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.10 : 0.06);

    final User? authUser = sl<FirebaseAuth>().currentUser;
    String displayName = "User";
    if (_user != null) {
      displayName = "${_user!.firstName} ${_user!.lastName}".trim();
      if (displayName.isEmpty) displayName = "User";
    } else if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) {
      displayName = authUser.displayName!;
    }

    final String profileUrl = _user?.profileImageUrl ?? "";
    final Color cardColor = isDark ? surface.withValues(alpha: 0.5) : const Color(0xFFF3F2E4);
    final Color goldButtonColor = const Color(0xFFC79A00);

    int trueVisitedCount = 0;
    if (_user != null) {
      final secretBadgeIds = BadgeConstants.allBadges
          .where((b) => b.isSecret)
          .map((b) => b.id)
          .toList();
      trueVisitedCount = _user!.visitedLandmarks
          .where((id) => !secretBadgeIds.contains(id))
          .length;
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
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new,
                            color: onSurface, size: 20.r),
                      ),
                      const Spacer(),
                      Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontFamily: 'Marcellus',
                          color: onSurface,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(width: 20.r),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: theme.colorScheme.primary))
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Card
                              Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(top: 50.h),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(24.r),
                                      border: isDark
                                          ? Border.all(color: borderColor)
                                          : null,
                                      boxShadow: isDark
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              )
                                            ],
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(height: 60.h),
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            color: isDark
                                                ? onSurface
                                                : const Color(0xFF6B3A28),
                                            fontSize: 22.sp,
                                            fontFamily: "Marcellus",
                                          ),
                                        ),
                                        if (_user?.username.isNotEmpty == true) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            "@${_user!.username}",
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: 14.sp,
                                              fontFamily: "Marcellus",
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: 16.h),

                                        if (_user != null) ...[
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20.w, vertical: 8.h),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 16.w),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.black26
                                                  : Colors.white
                                                      .withValues(alpha: 0.6),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.place,
                                                    color: Colors.amber,
                                                    size: 18.r),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  "$trueVisitedCount Places Visited",
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: onSurface
                                                        .withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20.h),

                                          // Your Taste card — top 3 canonical
                                          // taste vector keys as gold pills.
                                          // Hidden when vector is empty or all
                                          // entries are zero/negative.
                                          if (_topTasteKeys.isNotEmpty) ...[
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w),
                                              child: Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.fromLTRB(
                                                    14.w, 10.h, 14.w, 12.h),
                                                decoration: BoxDecoration(
                                                  color: goldButtonColor
                                                      .withValues(alpha: 0.10),
                                                  borderRadius:
                                                      BorderRadius.circular(14.r),
                                                  border: Border.all(
                                                      color: goldButtonColor
                                                          .withValues(alpha: 0.30)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.auto_awesome,
                                                            size: 14.r,
                                                            color: goldButtonColor),
                                                        SizedBox(width: 6.w),
                                                        Text(
                                                          'Your Taste',
                                                          style: TextStyle(
                                                            fontSize: 13.sp,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: goldButtonColor,
                                                            fontFamily: 'Marcellus',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: _topTasteKeys
                                                          .map((k) => Container(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            10.w,
                                                                        vertical:
                                                                            5.h),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: goldButtonColor
                                                                      .withValues(
                                                                          alpha:
                                                                              0.18),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20.r),
                                                                ),
                                                                child: Text(
                                                                  _prettyTasteKey(k),
                                                                  style: TextStyle(
                                                                    fontSize: 12.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        goldButtonColor,
                                                                  ),
                                                                ),
                                                              ))
                                                          .toList(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                          ],

                                          // Badges
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.w),
                                            child: Builder(
                                              builder: (context) {
                                                final displayBadges =
                                                    BadgeConstants.allBadges
                                                        .where((b) =>
                                                            !b.isSecret ||
                                                            _user!
                                                                .visitedLandmarks
                                                                .contains(b.id))
                                                        .toList();
                                                return Wrap(
                                                  alignment:
                                                      WrapAlignment.center,
                                                  spacing: 6,
                                                  runSpacing: 10,
                                                  children: List.generate(
                                                    displayBadges.length,
                                                    (index) {
                                                      final badge =
                                                          displayBadges[index];
                                                      final isUnlocked = _user!
                                                              .visitedLandmarks
                                                              .contains(
                                                                  badge.id) ||
                                                          (trueVisitedCount >=
                                                                  badge
                                                                      .requiredVisits &&
                                                              !badge.isSecret);
                                                      return _buildBadgeIcon(
                                                          badge,
                                                          isUnlocked,
                                                          onSurface);
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(height: 20.h),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Profile Avatar (overlapping)
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: goldButtonColor, width: 3),
                                    ),
                                    child: ShimmerAvatar(
                                      url: profileUrl,
                                      radius: 49.r,
                                      iconSize: 60.r,
                                      fallbackBackgroundColor: surface,
                                      fallbackIconColor:
                                          onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 30.h),

                              Text(
                                "Account Settings:",
                                style: TextStyle(
                                  color: isDark
                                      ? onSurface
                                      : const Color(0xFF6B3A28),
                                  fontSize: 16.sp,
                                  fontFamily: "Marcellus",
                                ),
                              ),
                              SizedBox(height: 16.h),

                              _AccountTile(
                                title: "Edit Profile",
                                icon: Icons.person_outline_rounded,
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
                              ),

                              if (_user?.role == 'tourist') ...[
                                if (_user?.applicationStatus == 'pending')
                                  _ApplicationStatusTile(
                                    status: 'pending',
                                    surface: surface,
                                    onSurface: onSurface,
                                    borderColor: borderColor,
                                    shadow: tileShadow,
                                  )
                                else if (_user?.applicationStatus == 'rejected')
                                  _ApplicationStatusTile(
                                    status: 'rejected',
                                    surface: surface,
                                    onSurface: onSurface,
                                    borderColor: borderColor,
                                    shadow: tileShadow,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider(
                                          create: (context) =>
                                              lost_in_egypt_guide_cubit
                                                  .ApplyGuideCubit(
                                            applyGuideUseCase: GetIt.I(),
                                          ),
                                          child: const lost_in_egypt_guide_screen
                                              .ApplyGuideScreen(),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  _AccountTile(
                                    title: "Apply to be a Guide",
                                    icon: Icons.badge_outlined,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BlocProvider(
                                            create: (context) =>
                                                lost_in_egypt_guide_cubit
                                                    .ApplyGuideCubit(
                                              applyGuideUseCase: GetIt.I(),
                                            ),
                                            child: const lost_in_egypt_guide_screen
                                                .ApplyGuideScreen(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                              _AccountTile(
                                title: "My Bookings",
                                icon: Icons.calendar_today_outlined,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const BookingHistoryScreen())),
                              ),
                              _AccountTile(
                                title: "Saved Posts",
                                icon: Icons.bookmark_outline_rounded,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SavedPostsScreen())),
                              ),
                              _AccountTile(
                                title: "My Plans",
                                icon: Icons.map_outlined,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => const MyPlansScreen())),
                              ),
                              _AccountTile(
                                title: "Membership",
                                icon: Icons.workspace_premium_outlined,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const YourPlanScreen()),
                                ),
                              ),

                              SizedBox(height: 24.h),

                              SizedBox(
                                width: double.infinity,
                                height: 56.h,
                                child: ElevatedButton(
                                  onPressed: () => _handleSignOut(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: goldButtonColor,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    "Sign out",
                                    style: TextStyle(fontSize: 18.sp),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30.h),
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
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border.all(
              color: isUnlocked
                  ? Colors.amber
                  : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: isUnlocked
              ? Icon(badge.iconData, color: Colors.amber, size: 22.r)
              : Icon(Icons.lock, color: Colors.grey, size: 18.r),
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: 64.w,
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

class _ApplicationStatusTile extends StatelessWidget {
  final String status;
  final Color surface;
  final Color onSurface;
  final Color borderColor;
  final BoxShadow shadow;
  final VoidCallback? onTap;

  const _ApplicationStatusTile({
    required this.status,
    required this.surface,
    required this.onSurface,
    required this.borderColor,
    required this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final statusColor = isPending ? Colors.orange : Colors.red;
    final statusLabel = isPending ? 'Under Review' : 'Not Approved';
    final statusIcon =
        isPending ? Icons.hourglass_top_rounded : Icons.cancel_outlined;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [shadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: SizedBox(
              height: 56.h,
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, color: statusColor, size: 20.r),
                  SizedBox(width: 10.w),
                  Text(
                    'Guide Application',
                    style: TextStyle(
                        color: onSurface.withValues(alpha: 0.85),
                        fontSize: 16.sp),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13.r, color: statusColor),
                        SizedBox(width: 4.w),
                        Text(
                          statusLabel,
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: statusColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (!isPending) ...[
                    SizedBox(width: 6.w),
                    Icon(Icons.chevron_right,
                        color: onSurface.withValues(alpha: 0.5)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AccountTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.hardEdge,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            height: 64.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.2 : 0.15),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: primary, size: 20.r),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.88),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Marcellus',
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: primary.withValues(alpha: 0.6), size: 22.r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
