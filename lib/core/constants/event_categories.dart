import 'package:lost_in_egypt/l10n/app_localizations.dart';

/// Event category constants for the events section.
/// Each category has an emoji, display name, and Firestore key.
class EventCategory {
  final String id;
  final String emoji;
  final String displayName;

  const EventCategory({
    required this.id,
    required this.emoji,
    required this.displayName,
  });

  String get label => '$emoji $displayName';
}

class EventCategories {
  EventCategories._();

  static const all = EventCategory(
    id: 'all',
    emoji: '✨',
    displayName: 'All',
  );

  static const cultural = EventCategory(
    id: 'cultural',
    emoji: '🏛',
    displayName: 'Cultural & Heritage',
  );

  static const concert = EventCategory(
    id: 'concert',
    emoji: '🎵',
    displayName: 'Concerts & Music',
  );

  static const theatre = EventCategory(
    id: 'theatre',
    emoji: '🎭',
    displayName: 'Theatre & Performance',
  );

  static const festival = EventCategory(
    id: 'festival',
    emoji: '🎪',
    displayName: 'Festivals',
  );

  static const art = EventCategory(
    id: 'art',
    emoji: '🖼',
    displayName: 'Art & Exhibitions',
  );

  static const adventure = EventCategory(
    id: 'adventure',
    emoji: '🌊',
    displayName: 'Adventure & Outdoors',
  );

  static const food = EventCategory(
    id: 'food',
    emoji: '🍽',
    displayName: 'Food & Markets',
  );

  static const cruise = EventCategory(
    id: 'cruise',
    emoji: '🚢',
    displayName: 'Cruise & Dining',
  );

  /// All categories for filter chips (includes "All" as first item).
  static const List<EventCategory> values = [
    all,
    cultural,
    concert,
    theatre,
    festival,
    art,
    adventure,
    food,
    cruise,
  ];

  /// Categories without "All" — for assigning to events.
  static const List<EventCategory> assignable = [
    cultural,
    concert,
    theatre,
    festival,
    art,
    adventure,
    food,
    cruise,
  ];

  /// All Egyptian cities that host events.
  static const List<String> cities = [
    'All Cities',
    'Cairo',
    'Luxor',
    'Aswan',
    'Alexandria',
    'Hurghada',
    'Sharm El-Sheikh',
    'Dahab',
    'Siwa',
    'El Gouna',
    'Fayoum',
  ];

  /// Lookup category by id.
  static EventCategory fromId(String id) {
    return values.firstWhere(
      (c) => c.id == id,
      orElse: () => cultural,
    );
  }
}

/// Localized chip label for an event category — `emoji + localized name`.
/// The `id`s are a fixed, bounded set; the const `displayName` (English) is
/// kept as the fallback for any unrecognised id. Mirrors `mapCategoryLabel`.
String eventCategoryLabel(AppLocalizations l10n, EventCategory cat) {
  final String name;
  switch (cat.id) {
    case 'all':
      name = l10n.eventCatAll;
      break;
    case 'cultural':
      name = l10n.eventCatCultural;
      break;
    case 'concert':
      name = l10n.eventCatConcert;
      break;
    case 'theatre':
      name = l10n.eventCatTheatre;
      break;
    case 'festival':
      name = l10n.eventCatFestival;
      break;
    case 'art':
      name = l10n.eventCatArt;
      break;
    case 'adventure':
      name = l10n.eventCatAdventure;
      break;
    case 'food':
      name = l10n.eventCatFood;
      break;
    case 'cruise':
      name = l10n.eventCatCruise;
      break;
    default:
      name = cat.displayName;
  }
  return '${cat.emoji} $name';
}
