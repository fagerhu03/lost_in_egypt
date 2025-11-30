import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      width: double.infinity,
      child: Row(
        children: [
          const SizedBox(width: 12),

          // 🔍 SEARCH BAR (full expand)
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xff4D5420).withOpacity(0.50), // black with 30% opacity
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

          // 👤 PROFILE BUTTON
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xff4D5420).withOpacity(0.50), // black with 30% opacity
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 26,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}
