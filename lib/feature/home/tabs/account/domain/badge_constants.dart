import 'package:flutter/material.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'badge_model.dart';

/// Localized badge name (display only). The badge `id` stays the stable key
/// used for unlock logic / Firestore; only the rendered label is translated.
/// Falls back to the English `name` for any unmapped id.
String badgeName(AppLocalizations l10n, BadgeModel badge) {
  switch (badge.id) {
    case 'novice_explorer':
      return l10n.badgeNoviceExplorer;
    case 'tourist':
      return l10n.badgeTourist;
    case 'tomb_raider':
      return l10n.badgeTombRaider;
    case 'historian':
      return l10n.badgeHistorian;
    case 'pharaoh':
      return l10n.badgePharaoh;
    case 'imhotep_secret':
      return l10n.badgeImhotep;
    case 'easter_egg_pharaoh':
      return l10n.badgeDeveloperPharaoh;
    case 'sphinx_solver':
      return l10n.badgeRiddleSolver;
    default:
      return badge.name;
  }
}

/// Localized badge description (display only). Falls back to English.
String badgeDescription(AppLocalizations l10n, BadgeModel badge) {
  switch (badge.id) {
    case 'novice_explorer':
      return l10n.badgeNoviceExplorerDesc;
    case 'tourist':
      return l10n.badgeTouristDesc;
    case 'tomb_raider':
      return l10n.badgeTombRaiderDesc;
    case 'historian':
      return l10n.badgeHistorianDesc;
    case 'pharaoh':
      return l10n.badgePharaohDesc;
    case 'imhotep_secret':
      return l10n.badgeImhotepDesc;
    case 'easter_egg_pharaoh':
      return l10n.badgeDeveloperPharaohDesc;
    case 'sphinx_solver':
      return l10n.badgeRiddleSolverDesc;
    default:
      return badge.description;
  }
}

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
