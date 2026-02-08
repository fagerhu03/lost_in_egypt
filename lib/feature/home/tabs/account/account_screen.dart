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

  static const Color _bg = Color(0xffFCFBE8);
  static const Color _text = Color(0xFF714611);
  static const Color _gold = Color(0xFFC79A00);

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
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data()!, doc.id);
        setState(() => _profileImageUrl = userModel.profileImageUrl);
      }
    } catch (e) {
      debugPrint("Error loading profile image: $e");
    }
  }

  // ✅ Helper to handle Sign Out - IMPROVED: Clears state
  Future<void> _handleSignOut(BuildContext context) async {
    // ✅ Clear state before signing out
    FirebaseAuth.instance.signOut();

    if (context.mounted) {
      // Navigate to login and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get the current user
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? "User";
    final String email = user?.email ?? "";

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.40,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
                errorBuilder: (c, o, s) => Container(), // Safety check
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back Arrow
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: _text,
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
                        // ✅ Dynamic Avatar + Name + Email
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
                                  color: const Color(
                                    0xFF714611,
                                  ).withOpacity(0.50),
                                  // ✅ Show Firestore profile image if available
                                  child: _profileImageUrl.isNotEmpty
                                      ? Image.network(
                                          _profileImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, o, s) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 60,
                                                ),
                                              ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
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
                                    style: const TextStyle(
                                      color: _text,
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
                                        color: _text.withOpacity(0.7),
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

                        const Text(
                          "Account Settings:",
                          style: TextStyle(
                            color: _text,
                            fontSize: 20,
                            fontFamily: "Marcellus",
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ✅ Added onTap placeholders for future steps
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
                            // ✅ Reload profile image after edit
                            _loadProfileImage();
                          },
                        ),
                        _AccountTile(title: "Places", onTap: () {}),
                        const SizedBox(height: 12),
                        _AccountTile(title: "Cards Detail", onTap: () {}),
                        const SizedBox(height: 12),
                        _AccountTile(title: "Registered tours", onTap: () {}),
                        const SizedBox(height: 12),
                        _AccountTile(title: "Your plan", onTap: () {}),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ✅ Working Sign Out Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _handleSignOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        "Sign out",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "Marcellus",
                          fontWeight: FontWeight.w500,
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
  final VoidCallback onTap; // ✅ Added onTap

  const _AccountTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ FIX: Force vertical spacing with margin
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xffFFFEF0),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x9E7C6A4D),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF714611),
                  fontSize: 16,
                  fontFamily: "Marcellus",
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Color(0xFF714611)),
            ],
          ),
        ),
      ),
    );
  }
}
