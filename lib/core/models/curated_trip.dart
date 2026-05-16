/// A single stop (place) within a curated trip itinerary.
class CuratedTripStop {
  final String name;
  final String description;

  /// Human-readable duration shown on the stop card, e.g. "1–2 hours".
  final String estimatedDuration;

  /// Canonical engine type (used for the icon in the detail screen).
  final String type;

  /// Precise GPS coordinates for in-app navigation & map focus.
  final double? lat;
  final double? lng;

  const CuratedTripStop({
    required this.name,
    required this.description,
    required this.estimatedDuration,
    required this.type,
    this.lat,
    this.lng,
  });

  bool get hasCoordinates => lat != null && lng != null;
}

/// A single day grouping of stops inside a curated trip.
class CuratedTripDay {
  final int day;
  final String label;
  final List<CuratedTripStop> stops;

  const CuratedTripDay({
    required this.day,
    required this.label,
    required this.stops,
  });
}

/// A pre-curated trip plan hand-picked by the Lost in Egypt team.
///
/// Trips are scored client-side against the user's taste vector from Firestore
/// so the best match can be surfaced on the SoloTripPage with a "Best for you"
/// badge.  [scoreAgainst] does a simple sum of taste vector values for all keys
/// listed in [scoringKeys] — higher sum = stronger personal match.
class CuratedTrip {
  final String id;
  final String title;

  /// One-line tagline shown below the title on detail screen.
  final String tagline;

  final String imagePath;

  /// Primary Egyptian city/region, shown in the PlanCard location row.
  final String primaryArea;

  /// All areas the trip visits (may be more than one).
  final List<String> areas;

  final int durationDays;

  /// Per-person estimated budget range in EGP, e.g. "500–1,500 EGP".
  final String budgetRange;

  /// Quiz interest labels that best match this trip (for display).
  final List<String> interests;

  /// Canonical engine keys (types + tags) used for taste-vector scoring.
  /// These should be the most *characteristic* keys for this trip, not
  /// every possible applicable key — this keeps differentiation sharp.
  final List<String> scoringKeys;

  /// 3 bullet-point highlights shown on PlanCard and detail screen.
  final List<String> highlights;

  /// Short label for the ideal traveller, e.g. "History & culture lovers".
  final String bestFor;

  final double rating;

  final List<CuratedTripDay> days;

  /// Approximate center latitude of the primary area (for location scoring).
  final double centerLat;

  /// Approximate center longitude of the primary area (for location scoring).
  final double centerLng;

  const CuratedTrip({
    required this.id,
    required this.title,
    required this.tagline,
    required this.imagePath,
    required this.primaryArea,
    required this.areas,
    required this.durationDays,
    required this.budgetRange,
    required this.interests,
    required this.scoringKeys,
    required this.highlights,
    required this.bestFor,
    required this.rating,
    required this.days,
    required this.centerLat,
    required this.centerLng,
  });

  String get durationLabel =>
      durationDays == 1 ? '1 day' : '$durationDays days';

  /// All stops across all days, in order.
  List<CuratedTripStop> get allStops =>
      days.expand((d) => d.stops).toList();

  /// Scores this trip against a Firestore taste vector.
  ///
  /// The taste vector is a flat map of canonical engine keys → float scores.
  /// Returns the sum of values for all [scoringKeys]. Missing keys are 0.
  double scoreAgainst(Map<String, dynamic> tasteVector) {
    double score = 0;
    for (final key in scoringKeys) {
      score += (tasteVector[key] as num?)?.toDouble() ?? 0;
    }
    return score;
  }
}
