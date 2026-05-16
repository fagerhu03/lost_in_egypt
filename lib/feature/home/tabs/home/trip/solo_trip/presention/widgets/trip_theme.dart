import 'package:flutter/material.dart';

/// Visual theme for a curated trip — gradient, icon, and Places API photo
/// query used by PlanCard thumbnail and CuratedTripDetailScreen hero.
class TripTheme {
  final List<Color> gradient;
  final IconData icon;
  final String emoji;
  final String photoQuery;

  const TripTheme({
    required this.gradient,
    required this.icon,
    required this.emoji,
    required this.photoQuery,
  });

  static TripTheme forId(String id) => switch (id) {
        'islamic_cairo' => const TripTheme(
            gradient: [Color(0xFFB5651D), Color(0xFF3E1C00)],
            icon: Icons.mosque_outlined,
            emoji: '🕌',
            photoQuery: 'Khan el-Khalili Bazaar Cairo Egypt',
          ),
        'coastal_alexandria' => const TripTheme(
            gradient: [Color(0xFF0096C7), Color(0xFF023E8A)],
            icon: Icons.waves_outlined,
            emoji: '🌊',
            photoQuery: 'Bibliotheca Alexandrina Egypt',
          ),
        'greco_roman' => const TripTheme(
            gradient: [Color(0xFF8D7B68), Color(0xFF2D1B0E)],
            icon: Icons.account_balance_outlined,
            emoji: '🏛',
            photoQuery: 'Catacombs Kom el-Shoqafa Alexandria Egypt',
          ),
        'luxor_temples' => const TripTheme(
            gradient: [Color(0xFFE07B39), Color(0xFF7C1D00)],
            icon: Icons.explore_outlined,
            emoji: '🔺',
            photoQuery: 'Karnak Temple Luxor Egypt',
          ),
        'aswan_nubia' => const TripTheme(
            gradient: [Color(0xFFC1440E), Color(0xFF3B0A00)],
            icon: Icons.water_outlined,
            emoji: '⛵',
            photoQuery: 'Philae Temple Aswan Egypt',
          ),
        'hurghada_red_sea' => const TripTheme(
            gradient: [Color(0xFF00B4D8), Color(0xFF005F73)],
            icon: Icons.beach_access_outlined,
            emoji: '🐠',
            photoQuery: 'Red Sea coral reef Hurghada Egypt',
          ),
        'sharm_sinai' => const TripTheme(
            gradient: [Color(0xFF1565C0), Color(0xFF0D1B2A)],
            icon: Icons.terrain_outlined,
            emoji: '⛰',
            photoQuery: 'Ras Mohammed National Park Sharm El-Sheikh Egypt',
          ),
        'siwa_oasis' => const TripTheme(
            gradient: [Color(0xFF52796F), Color(0xFF1B3A2D)],
            icon: Icons.park_outlined,
            emoji: '🌴',
            photoQuery: 'Siwa Oasis Egypt',
          ),
        _ => const TripTheme(
            gradient: [Color(0xFFD6A00F), Color(0xFF5C3D00)],
            icon: Icons.place_outlined,
            emoji: '🗺',
            photoQuery: 'Egypt landmarks',
          ),
      };
}
