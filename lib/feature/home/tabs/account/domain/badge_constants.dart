import 'badge_model.dart';

class BadgeConstants {
  static const List<BadgeModel> allBadges = [
    BadgeModel(
      id: 'novice_explorer',
      name: 'Novice Explorer',
      description: 'Discovered your first landmark.',
      requiredVisits: 1,
      iconAsset: 'assets/badges/novice.png', // Fallback or setup later
    ),
    BadgeModel(
      id: 'tourist',
      name: 'Tourist',
      description: 'Visited 3 landmarks.',
      requiredVisits: 3,
      iconAsset: 'assets/badges/tourist.png',
    ),
    BadgeModel(
      id: 'tomb_raider',
      name: 'Tomb Raider',
      description: 'Visited 5 landmarks.',
      requiredVisits: 5,
      iconAsset: 'assets/badges/raider.png',
    ),
    BadgeModel(
      id: 'historian',
      name: 'Historian',
      description: 'Visited 10 landmarks.',
      requiredVisits: 10,
      iconAsset: 'assets/badges/historian.png',
    ),
    BadgeModel(
      id: 'pharaoh',
      name: 'Pharaoh',
      description: 'Visited 20 landmarks.',
      requiredVisits: 20,
      iconAsset: 'assets/badges/pharaoh.png',
    ),
  ];
}
