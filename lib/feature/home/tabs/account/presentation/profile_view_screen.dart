import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_constants.dart';

class ProfileViewScreen extends StatefulWidget {
  final String? uid; // optional: view other user's profile if provided
  const ProfileViewScreen({Key? key, this.uid}) : super(key: key);

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    // visible shadows: dark in light mode, glow in dark mode
    final cardShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.14)
          : Colors.black.withOpacity(0.14),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 10),
    );

    final borderColor =
    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: TextStyle(color: onSurface)),
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
          'User not found',
          style: TextStyle(color: onSurface.withOpacity(0.8)),
        ),
      )
          : ListView(
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [cardShadow],
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: primary.withOpacity(0.18),
                    child: _user!.profileImageUrl.isNotEmpty
                        ? ClipOval(child: CachedNetworkImage(imageUrl: _user!.profileImageUrl, width: 108, height: 108, fit: BoxFit.cover, errorWidget: (_, _, _) => Icon(Icons.person, size: 48, color: onSurface)))
                        : Icon(Icons.person, size: 48, color: onSurface),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_user!.firstName} ${_user!.lastName}',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Marcellus',
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (_user!.nationality.isNotEmpty)
                  Text(
                    _user!.nationality,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.55),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge('Email', _user!.emailVerified),
                    const SizedBox(width: 12),
                    _buildBadge('Phone', _user!.phoneVerified),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat('Posts', _postCount, onSurface),
                    const SizedBox(width: 24),
                    _buildStat('Places', _user!.visitedLandmarks.length, onSurface),
                    const SizedBox(width: 24),
                    _buildStat('Role', 0, onSurface,
                        label: _user!.role.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_user!.bio.isNotEmpty)
            _sectionCard(
              title: 'About',
              child: Text(
                _user!.bio,
                style: TextStyle(color: onSurface.withOpacity(0.85)),
              ),
              surface: surface,
              onSurface: onSurface,
              shadow: cardShadow,
              borderColor: borderColor,
            ),

          if (_user!.interests.isNotEmpty)
            _sectionCard(
              title: 'Interests',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user!.interests
                    .map(
                      (i) => Chip(
                    label: Text(
                      i,
                      style:
                      TextStyle(color: onSurface.withOpacity(0.9)),
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
              title: 'Social',
              child: Column(
                children: [
                  if (_user!.instagramHandle.isNotEmpty)
                    _buildSocialRow(
                      'Instagram',
                      _user!.instagramHandle,
                      onSurface,
                    ),
                  if (_user!.twitterHandle.isNotEmpty)
                    _buildSocialRow(
                      'Twitter',
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
            title: 'Contact',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.email,
                  style:
                  TextStyle(color: onSurface.withOpacity(0.85)),
                ),
                const SizedBox(height: 6),
                if (_user!.phoneNumber.isNotEmpty)
                  Text(
                    _user!.phoneNumber,
                    style: TextStyle(
                        color: onSurface.withOpacity(0.85)),
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
            title: 'Badges',
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: BadgeConstants.allBadges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
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

          const SizedBox(height: 18),

          if (widget.uid == null || widget.uid == _currentUid)
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                    context, '/edit_profile_enhanced'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.black.withOpacity(0.22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Edit profile'),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildBadge(String label, bool good) {
    return Row(
      children: [
        Icon(
          good ? Icons.check_circle : Icons.radio_button_unchecked,
          color: good ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
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
        const SizedBox(height: 4),
        Text(name, style: TextStyle(color: onSurface.withOpacity(0.55))),
      ],
    );
  }

  Widget _buildSocialRow(String service, String handle, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              style: TextStyle(color: onSurface.withOpacity(0.85)),
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
              width: 60,
              height: 60,
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
                  ? const Icon(Icons.star, color: Colors.amber, size: 30)
                  : const Icon(Icons.lock, color: Colors.grey, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          badge.name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            color: isUnlocked ? onSurface : onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}