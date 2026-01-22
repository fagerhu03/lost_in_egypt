import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const Color _bg = Color(0xFFF6F2E6);
  static const Color _text = Color(0xFF714611);
  static const Color _gold = Color(0xFFC79A00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ✅ Back Arrow (pop)
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
                        // Avatar + name
                        Row(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Container(
                                  color: const Color(0xFF714611).withOpacity(0.50),
                                  child: const Center(
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
                            const Text(
                              "Nicole John",
                              style: TextStyle(
                                color: _text,
                                fontSize: 24,
                                fontFamily: "Marcellus",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Account Settings:",
                          style: TextStyle(
                            color: _text,
                            fontSize: 16,
                            fontFamily: "Marcellus",
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const _AccountTile(title: "Edit Profile"),
                        const SizedBox(height: 12),
                        const _AccountTile(title: "Places"),
                        const SizedBox(height: 12),
                        const _AccountTile(title: "Cards Detail"),
                        const SizedBox(height: 12),
                        const _AccountTile(title: "Registered tours"),
                        const SizedBox(height: 12),
                        const _AccountTile(title: "Your plan"),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
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
                          fontSize: 16,
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
  const _AccountTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7C6A4D),
              fontSize: 14,
              fontFamily: "Marcellus",
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Color(0xFF7C6A4D)),
        ],
      ),
    );
  }
}
