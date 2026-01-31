import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../auth/data/models/user.dart';
import '../navigator/widget/account_menu_button.dart';
import 'settings_screen.dart';
import 'currency_converter_screen.dart';
import 'translator_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ✅ Fetch user photo from Firestore on init
  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!, doc.id);
        if (mounted) {
          setState(() {
            _profileImageUrl = user.profileImageUrl;
          });
        }
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _handleSignOut() async {
    // ✅ Clear state before signing out
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => Container(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: Center(
                          child: const Text(
                            "More",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7C6A4D),
                            ),
                          ),
                        ),
                      ),
                      // ✅ Now passes the real image URL
                      AccountMenuButton(
                        profileImageUrl: _profileImageUrl,
                        onSignOut: _handleSignOut,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Tiles
                  _MoreTile(
                    title: "Currency",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CurrencyConverterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _MoreTile(
                    title: "Settings",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                      // Refresh profile image after returning from Settings
                      _loadUserProfile();
                    },
                  ),

                  _MoreTile(title: "Help", onTap: () {}),
                  const SizedBox(height: 12),

                  _MoreTile(
                    title: "Translator",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TranslatorScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _MoreTile(
                    title: "Contact us",
                    trailing: Icons.keyboard_arrow_down,
                    onTap: () {},
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... _MoreTile class remains the same ...
class _MoreTile extends StatelessWidget {
  final String title;
  final IconData trailing;
  final VoidCallback onTap;

  const _MoreTile({
    required this.title,
    required this.onTap,
    this.trailing = Icons.chevron_right,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7ED),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF7C6A4D),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(trailing, color: const Color(0xFF7C6A4D)),
          ],
        ),
      ),
    );
  }
}
