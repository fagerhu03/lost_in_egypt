import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsSheet {
  static void open(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _SheetBody(),
    );
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody();

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  bool _isLoading = true;

  bool _masterEnabled = true;
  bool _bookingsEnabled = true;
  bool _communityEnabled = true;
  bool _reviewsEnabled = true;
  bool _guideUpdatesEnabled = true;
  bool _dailyDiscoveryEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final prefs = (data['notificationPreferences'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _masterEnabled = ((data['preferences'] as Map<String, dynamic>?)?['notifications']) ?? true;
          _bookingsEnabled = prefs['bookings'] ?? true;
          _communityEnabled = prefs['community'] ?? true;
          _reviewsEnabled = prefs['reviews'] ?? true;
          _guideUpdatesEnabled = prefs['guideUpdates'] ?? true;
          _dailyDiscoveryEnabled = prefs['dailyDiscovery'] ?? true;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'preferences': {'notifications': _masterEnabled},
        'notificationPreferences': {
          'bookings': _bookingsEnabled,
          'community': _communityEnabled,
          'reviews': _reviewsEnabled,
          'guideUpdates': _guideUpdatesEnabled,
          'dailyDiscovery': _dailyDiscoveryEnabled,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              "Notification Preferences",
              style: TextStyle(
                color: onSurface,
                fontFamily: "Marcellus",
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Choose what you want to be notified about.",
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.65),
                fontFamily: "Marcellus",
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 18.h),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const Center(child: CircularProgressIndicator()),
              )
            else ...[
              _ToggleTile(
                icon: Icons.notifications_rounded,
                title: "All Notifications",
                subtitle: "Master switch for all push alerts",
                value: _masterEnabled,
                enabled: true,
                onChanged: (v) {
                  setState(() => _masterEnabled = v);
                  _save();
                },
              ),
              SizedBox(height: 8.h),
              Divider(color: onSurface.withValues(alpha: 0.10), height: 1),
              SizedBox(height: 8.h),
              Opacity(
                opacity: _masterEnabled ? 1.0 : 0.4,
                child: Column(
                  children: [
                    _ToggleTile(
                      icon: Icons.confirmation_number_rounded,
                      title: "Bookings & Tours",
                      subtitle: "Confirmations, cancellations, updates",
                      value: _bookingsEnabled,
                      enabled: _masterEnabled,
                      onChanged: (v) {
                        setState(() => _bookingsEnabled = v);
                        _save();
                      },
                    ),
                    SizedBox(height: 8.h),
                    _ToggleTile(
                      icon: Icons.people_alt_rounded,
                      title: "Community",
                      subtitle: "Likes, comments, mentions, replies",
                      value: _communityEnabled,
                      enabled: _masterEnabled,
                      onChanged: (v) {
                        setState(() => _communityEnabled = v);
                        _save();
                      },
                    ),
                    SizedBox(height: 8.h),
                    _ToggleTile(
                      icon: Icons.star_rounded,
                      title: "Reviews",
                      subtitle: "When someone reviews your tour",
                      value: _reviewsEnabled,
                      enabled: _masterEnabled,
                      onChanged: (v) {
                        setState(() => _reviewsEnabled = v);
                        _save();
                      },
                    ),
                    SizedBox(height: 8.h),
                    _ToggleTile(
                      icon: Icons.verified_user_rounded,
                      title: "Guide Updates",
                      subtitle: "Application & language certification results",
                      value: _guideUpdatesEnabled,
                      enabled: _masterEnabled,
                      onChanged: (v) {
                        setState(() => _guideUpdatesEnabled = v);
                        _save();
                      },
                    ),
                    SizedBox(height: 8.h),
                    _ToggleTile(
                      icon: Icons.auto_awesome_rounded,
                      title: "AI Discovery",
                      subtitle: "Daily 'Did you know?' fact about Egypt",
                      value: _dailyDiscoveryEnabled,
                      enabled: _masterEnabled,
                      onChanged: (v) {
                        setState(() => _dailyDiscoveryEnabled = v);
                        _save();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(
                        fontFamily: "Marcellus", fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: primary, size: 18.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: onSurface,
                        fontFamily: "Marcellus",
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp)),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: TextStyle(
                        color: onSurface.withValues(alpha: 0.60),
                        fontFamily: "Marcellus",
                        fontSize: 11.sp)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: primary,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
