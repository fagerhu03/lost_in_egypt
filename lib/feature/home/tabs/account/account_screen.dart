import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_profile_screen_enhanced.dart';
import '../../../auth/data/models/user.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromMap(doc.data()!, doc.id);
        setState(() => _profileImageUrl = userModel.profileImageUrl);
      }
    } catch (e) {
      debugPrint("Error loading profile image: $e");
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
    final primary = theme.colorScheme.primary;

    final patternOpacity = isDark ? 0.20 : 0.40;

    // visible shadows (dark in light mode, glow in dark mode)
    final tileShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.16)
          : Colors.black.withOpacity(0.16),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    );

    final borderColor =
    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    // current user
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? "User";
    final String email = user?.email ?? "";

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
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Container(
                                  color: primary.withOpacity(0.20),
                                  child: _profileImageUrl.isNotEmpty
                                      ? Image.network(
                                    _profileImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => Center(
                                      child: Icon(
                                        Icons.person,
                                        color: onSurface.withOpacity(0.9),
                                        size: 60,
                                      ),
                                    ),
                                  )
                                      : Center(
                                    child: Icon(
                                      Icons.person,
                                      color: onSurface.withOpacity(0.9),
                                      size: 60,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: onSurface,
                                      fontSize: 24,
                                      fontFamily: "Marcellus",
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: onSurface.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "Account Settings:",
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 20,
                            fontFamily: "Marcellus",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),

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
                            _loadProfileImage();
                          },
                          surface: surface,
                          onSurface: onSurface,
                          borderColor: borderColor,
                          shadow: tileShadow,
                        ),
                        _AccountTile(
                          title: "Places",
                          onTap: () {},
                          surface: surface,
                          onSurface: onSurface,
                          borderColor: borderColor,
                          shadow: tileShadow,
                        ),
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
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _handleSignOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isDark ? 0 : 6,
                      ),
                      child: const Text(
                        "Sign out",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: "Marcellus",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [shadow],
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: onSurface.withOpacity(0.9),
                  fontSize: 16,
                  fontFamily: "Marcellus",
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: onSurface.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }
}