import 'package:lost_in_egypt/l10n/app_localizations.dart';

/// Interest/area values are persisted and sent to the recommendation engine in
/// English (they double as canonical data keys). These resolvers localize only
/// the display label — unknown values pass through unchanged (e.g. AI-generated
/// or curated-trip area strings on the My Plans card).
String tripInterestLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Shopping':
      return l10n.soloInterestShopping;
    case 'Nightlife':
      return l10n.soloInterestNightlife;
    case 'Monuments':
      return l10n.soloInterestMonuments;
    case 'Museums':
      return l10n.soloInterestMuseums;
    case 'Nature & Parks':
      return l10n.soloInterestNature;
    case 'Beaches':
      return l10n.soloInterestBeaches;
    case 'Culture & Traditions':
      return l10n.soloInterestCulture;
    case 'Entertainment':
      return l10n.soloInterestEntertainment;
    case 'Adventure Activities':
      return l10n.soloInterestAdventure;
    case 'Local Experiences':
      return l10n.soloInterestLocal;
    default:
      return value;
  }
}

String tripAreaLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Cairo':
      return l10n.soloAreaCairo;
    case 'Luxor':
      return l10n.soloAreaLuxor;
    case 'Aswan':
      return l10n.soloAreaAswan;
    case 'Alexandria':
      return l10n.soloAreaAlexandria;
    case 'Hurghada':
      return l10n.soloAreaHurghada;
    case 'Sharm El-Sheikh':
      return l10n.soloAreaSharm;
    case 'Dahab':
      return l10n.soloAreaDahab;
    case 'Siwa':
      return l10n.soloAreaSiwa;
    case 'Fayoum':
      return l10n.soloAreaFayoum;
    case 'North Coast':
      return l10n.soloAreaNorthCoast;
    default:
      return value;
  }
}

class TripOptions {
  static const List<String> interests = [
    'Shopping',
    'Nightlife',
    'Monuments',
    'Museums',
    'Nature & Parks',
    'Beaches',
    'Culture & Traditions',
    'Entertainment',
    'Adventure Activities',
    'Local Experiences',
  ];

  static const List<String> areas = [
    'Cairo',
    'Luxor',
    'Aswan',
    'Alexandria',
    'Hurghada',
    'Sharm El-Sheikh',
    'Dahab',
    'Siwa',
    'Fayoum',
    'North Coast',
  ];

  static const List<String> tripTimes = [
    'Day',
    'Night',
  ];
}