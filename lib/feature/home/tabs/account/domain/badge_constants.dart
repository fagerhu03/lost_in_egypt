import 'package:flutter/material.dart';
import 'badge_model.dart';

class BadgeConstants {
  static const List<BadgeModel> allBadges = [
    BadgeModel(
      id: 'novice_explorer',
      name: 'Novice Explorer',
      description: 'Discovered your first landmark.',
      requiredVisits: 1,
      iconData: Icons.explore,
    ),
    BadgeModel(
      id: 'tourist',
      name: 'Tourist',
      description: 'Visited 3 landmarks.',
      requiredVisits: 3,
      iconData: Icons.camera_alt,
    ),
    BadgeModel(
      id: 'tomb_raider',
      name: 'Tomb Raider',
      description: 'Visited 5 landmarks.',
      requiredVisits: 5,
      iconData: Icons.account_balance,
    ),
    BadgeModel(
      id: 'historian',
      name: 'Historian',
      description: 'Visited 10 landmarks.',
      requiredVisits: 10,
      iconData: Icons.menu_book,
    ),
    BadgeModel(
      id: 'pharaoh',
      name: 'Pharaoh',
      description: 'Visited 20 landmarks.',
      requiredVisits: 20,
      iconData: Icons.person_pin,
    ),
    BadgeModel(
      id: 'imhotep_secret',
      name: 'High Priest Imhotep',
      description: 'You discovered the hidden vault of the architect.',
      requiredVisits: 99999,
      iconData: Icons.architecture,
      isSecret: true,
    ),
    BadgeModel(
      id: 'easter_egg_pharaoh',
      name: 'Developer Pharaoh',
      description: 'Discovered the hidden developer tomb.',
      requiredVisits: 99999,
      iconData: Icons.developer_mode,
      isSecret: true,
    ),
    BadgeModel(
      id: 'sphinx_solver',
      name: 'Riddle Solver',
      description: 'You answered the Riddle of the Sphinx.',
      requiredVisits: 99999,
      iconData: Icons.auto_awesome,
      isSecret: true,
    ),
  ];
}
