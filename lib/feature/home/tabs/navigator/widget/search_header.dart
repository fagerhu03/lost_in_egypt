import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback onSignOut;

  const SearchHeader({
    super.key,
    this.profileImageUrl,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      width: double.infinity,
      child: Row(
        children: [
          const SizedBox(width: 12),

          // 🔍 SEARCH BAR
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xff4D5420).withOpacity(0.50),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Where do you want to go?",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Marcellus",
                      ),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.95),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 👤 PROFILE DROPDOWN (Replaces the old static icon)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                onSignOut();
              }
            },
            offset: const Offset(0, 50),
            color: const Color(0xffFFFDF4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            
            // The Button UI
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff4D5420).withOpacity(0.50),
                shape: BoxShape.circle,
                image: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                  ? Icon(
                      Icons.person,
                      size: 26,
                      color: Colors.white.withOpacity(0.95),
                    )
                  : null,
            ),
            
            // The Menu Items
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    "My Account",
                    style: TextStyle(
                      fontFamily: "Marcellus",
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4D5420),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text("Sign Out", style: TextStyle(fontFamily: "Marcellus")),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}