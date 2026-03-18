import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class NotificationSettingsSheet {
  static void open(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
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
  bool _commentsEnabled = true;
  bool _likesEnabled = true;
  bool _mentionsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final Map<String, dynamic> prefs = data['notificationPreferences'] ?? {};
        if (mounted) {
          setState(() {
            _commentsEnabled = prefs['comments'] ?? true;
            _likesEnabled = prefs['likes'] ?? true;
            _mentionsEnabled = prefs['mentions'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'notificationPreferences': {
          'comments': _commentsEnabled,
          'likes': _likesEnabled,
          'mentions': _mentionsEnabled,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving preferences: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Notification Settings",
              style: TextStyle(
                color: onSurface,
                fontFamily: "Marcellus",
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Customize what you want to receive.",
              style: TextStyle(
                color: onSurface.withOpacity(0.7),
                fontFamily: "Marcellus",
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _SettingToggleTile(
                title: "Comments",
                subtitle: "Get notified when someone comments.",
                initialValue: _commentsEnabled,
                onChanged: (v) {
                  _commentsEnabled = v;
                  _savePreferences();
                },
              ),
              const SizedBox(height: 10),
              _SettingToggleTile(
                title: "Likes",
                subtitle: "Get notified when someone likes your post.",
                initialValue: _likesEnabled,
                onChanged: (v) {
                  _likesEnabled = v;
                  _savePreferences();
                },
              ),
              const SizedBox(height: 10),
              _SettingToggleTile(
                title: "Mentions",
                subtitle: "Get notified when someone mentions you.",
                initialValue: _mentionsEnabled,
                onChanged: (v) {
                  _mentionsEnabled = v;
                  _savePreferences();
                },
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      fontFamily: "Marcellus",
                      fontWeight: FontWeight.w600,
                    ),
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

class _SettingToggleTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const _SettingToggleTile({
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_SettingToggleTile> createState() => _SettingToggleTileState();
}

class _SettingToggleTileState extends State<_SettingToggleTile> {
  late bool _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: onSurface,
                    fontFamily: "Marcellus",
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.65),
                    fontFamily: "Marcellus",
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _value,
            activeColor: primary,
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
