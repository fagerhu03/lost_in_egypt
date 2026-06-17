import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_avatar.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_constants.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

class ProfileViewScreen extends StatefulWidget {
  final String? uid; // optional: view other user's profile if provided
  const ProfileViewScreen({super.key, this.uid});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  UserModel? _user;
  bool _isLoading = true;
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uidToLoad = widget.uid ?? _currentUid;
    if (uidToLoad == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uidToLoad)
          .get();

      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      }

      final query1 = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: uidToLoad)
          .get();

      if (query1.docs.isNotEmpty) {
        _postCount = query1.size;
      } else {
        final query2 = await FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: uidToLoad)
            .get();
        _postCount = query2.size;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    // visible shadows: dark in light mode, glow in dark mode
    final cardShadow = BoxShadow(
      color: isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.black.withValues(alpha: 0.14),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 10),
    );

    final borderColor =
    (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.10 : 0.06);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.profileViewTitle, style: TextStyle(color: onSurface)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _user == null
          ? Center(
        child: Text(
          l10n.profileUserNotFound,
          style: TextStyle(color: onSurface.withValues(alpha: 0.8)),
        ),
      )
          : ListView(
        padding:
        EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [cardShadow],
                  ),
                  child: ShimmerAvatar(
                    url: _user!.profileImageUrl,
                    radius: 54.r,
                    iconSize: 48.r,
                    fallbackBackgroundColor: primary.withValues(alpha: 0.18),
                    fallbackIconColor: onSurface,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  '${_user!.firstName} ${_user!.lastName}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                if (_user!.nationality.isNotEmpty)
                  Text(
                    _user!.nationality,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge(l10n.profileEmail, _user!.emailVerified),
                    SizedBox(width: 12.w),
                    _buildBadge(l10n.profilePhone, _user!.phoneVerified),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat(l10n.profilePostsStat, _postCount, onSurface),
                    SizedBox(width: 24.w),
                    _buildStat(l10n.profilePlacesStat, _user!.visitedLandmarks.length, onSurface),
                    SizedBox(width: 24.w),
                    _buildStat(l10n.profileRole, 0, onSurface,
                        label: _roleLabel(l10n).toUpperCase()),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          if (_user!.bio.isNotEmpty)
            _sectionCard(
              title: l10n.profileAbout,
              child: Text(
                _user!.bio,
                style: TextStyle(color: onSurface.withValues(alpha: 0.85)),
              ),
              surface: surface,
              onSurface: onSurface,
              shadow: cardShadow,
              borderColor: borderColor,
            ),

          if (_user!.interests.isNotEmpty)
            _sectionCard(
              title: l10n.profileInterests,
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _user!.interests
                    .map(
                      (i) => Chip(
                    label: Text(
                      i,
                      style:
                      TextStyle(color: onSurface.withValues(alpha: 0.9)),
                    ),
                    backgroundColor: surface,
                    side: BorderSide(color: borderColor),
                  ),
                )
                    .toList(),
              ),
              surface: surface,
              onSurface: onSurface,
              shadow: cardShadow,
              borderColor: borderColor,
            ),

          if (_user!.instagramHandle.isNotEmpty ||
              _user!.twitterHandle.isNotEmpty)
            _sectionCard(
              title: l10n.profileSocial,
              child: Column(
                children: [
                  if (_user!.instagramHandle.isNotEmpty)
                    _buildSocialRow(
                      l10n.profileInstagram,
                      _user!.instagramHandle,
                      onSurface,
                    ),
                  if (_user!.twitterHandle.isNotEmpty)
                    _buildSocialRow(
                      l10n.profileTwitter,
                      _user!.twitterHandle,
                      onSurface,
                    ),
                ],
              ),
              surface: surface,
              onSurface: onSurface,
              shadow: cardShadow,
              borderColor: borderColor,
            ),

          _sectionCard(
            title: l10n.profileContact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.email,
                  style:
                  TextStyle(color: onSurface.withValues(alpha: 0.85)),
                ),
                SizedBox(height: 6.h),
                if (_user!.phoneNumber.isNotEmpty)
                  Text(
                    _user!.phoneNumber,
                    style: TextStyle(
                        color: onSurface.withValues(alpha: 0.85)),
                  ),
              ],
            ),
            surface: surface,
            onSurface: onSurface,
            shadow: cardShadow,
            borderColor: borderColor,
          ),

          // --- GAMIFICATION BADGES ---
          _sectionCard(
            title: l10n.profileBadges,
            child: SizedBox(
              height: 100.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: BadgeConstants.allBadges.length,
                separatorBuilder: (_, _) => SizedBox(width: 16.w),
                itemBuilder: (context, index) {
                  final badge = BadgeConstants.allBadges[index];
                  final isUnlocked = _user!.visitedLandmarks.length >= badge.requiredVisits;

                  return _buildBadgeIcon(badge, isUnlocked, onSurface);
                },
              ),
            ),
            surface: surface,
            onSurface: onSurface,
            shadow: cardShadow,
            borderColor: borderColor,
          ),

          SizedBox(height: 18.h),

          if (widget.uid == null || widget.uid == _currentUid)
            SizedBox(
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                    context, '/edit_profile_enhanced'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(l10n.editProfileTitle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    required Color surface,
    required Color onSurface,
    required BoxShadow shadow,
    required Color borderColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [shadow],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n) {
    switch (_user!.role) {
      case 'admin':
        return l10n.profileRoleAdmin;
      case 'guide':
        return l10n.profileRoleVerifiedGuide;
      default:
        return l10n.profileRoleTourist;
    }
  }

  Widget _buildBadge(String label, bool good) {
    return Row(
      children: [
        Icon(
          good ? Icons.check_circle : Icons.radio_button_unchecked,
          color: good ? Colors.green : Colors.grey,
          size: 16.r,
        ),
        SizedBox(width: 6.w),
        Text(label, style: TextStyle(color: good ? Colors.green : Colors.grey)),
      ],
    );
  }

  Widget _buildStat(String name, int value, Color onSurface, {String? label}) {
    return Column(
      children: [
        Text(
          label ?? value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        SizedBox(height: 4.h),
        Text(name, style: TextStyle(color: onSurface.withValues(alpha: 0.55))),
      ],
    );
  }

  Widget _buildSocialRow(String service, String handle, Color onSurface) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Text(
            '$service: ',
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              handle,
              style: TextStyle(color: onSurface.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(dynamic badge, bool isUnlocked, Color onSurface) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60.r,
              height: 60.r,
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
                  ? Icon(Icons.star, color: Colors.amber, size: 30.r)
                  : Icon(Icons.lock, color: Colors.grey, size: 24.r),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          badgeName(AppLocalizations.of(context), badge),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            color: isUnlocked ? onSurface : onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
