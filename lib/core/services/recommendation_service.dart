import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/weather_context.dart';

// ── Result models ─────────────────────────────────────────────────────────────

/// A single place returned by the recommendation engine, ranked by score.
class RecommendedPlace {
  final String placeId;
  final String name;

  /// Composite score in roughly [−1, 1]. Higher = stronger match.
  final double score;

  /// Zero-based position in the ranked list.
  final int rank;

  /// Up to 2 human-readable reasons (e.g. "Matches your love of history",
  /// "4.8★ — highly rated", "2.3 km away"). Shown as chips on result cards.
  final List<String> reasons;

  /// True when the engine used ε-greedy exploration for this slot instead of
  /// the scored ranking — i.e. this is a serendipity pick, not a taste match.
  final bool isExploration;

  const RecommendedPlace({
    required this.placeId,
    required this.name,
    required this.score,
    required this.rank,
    required this.reasons,
    required this.isExploration,
  });

  factory RecommendedPlace.fromMap(Map<String, dynamic> m) => RecommendedPlace(
        placeId: m['placeId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        score: (m['score'] as num?)?.toDouble() ?? 0,
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        reasons: List<String>.from(m['reasons'] as List? ?? []),
        isExploration: m['exploration'] as bool? ?? false,
      );
}

/// Full response from the `recommendPlaces` Cloud Function.
class RecommendationResult {
  final List<RecommendedPlace> recommendations;

  /// How many interaction signals this user has accumulated so far.
  final int signalCount;

  /// True once the user has ≥5 non-quiz signals — at this point personal taste
  /// drives scoring instead of country-level priors.
  final bool hasEnoughSignals;

  /// True when the cold-start country-prior fallback was used for scoring
  /// (only happens when hasEnoughSignals is false).
  final bool usedCountryPrior;

  /// Number of Places API candidates that were evaluated and scored.
  final int candidatesEvaluated;

  const RecommendationResult({
    required this.recommendations,
    required this.signalCount,
    required this.hasEnoughSignals,
    required this.usedCountryPrior,
    required this.candidatesEvaluated,
  });

  factory RecommendationResult.fromMap(Map<String, dynamic> m) {
    final recs = (m['recommendations'] as List? ?? [])
        .map((r) => RecommendedPlace.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
    final meta = Map<String, dynamic>.from(m['meta'] as Map? ?? {});
    return RecommendationResult(
      recommendations: recs,
      signalCount: (meta['signalCount'] as num?)?.toInt() ?? 0,
      hasEnoughSignals: meta['hasEnoughSignals'] as bool? ?? false,
      usedCountryPrior: meta['usedCountryPrior'] as bool? ?? false,
      candidatesEvaluated: (meta['candidatesEvaluated'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Static singleton that wraps the recommendation Cloud Functions.
/// Same pattern as [CurrencyService] — not registered in GetIt.
///
/// All public methods are fire-and-forget safe: they catch and log errors
/// rather than throwing, so callers never need try/catch.
class RecommendationService {
  RecommendationService._();

  static final _fns = FirebaseFunctions.instance;

  static HttpsCallable _fn(String name) => _fns.httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

  // ── Signal recording ───────────────────────────────────────────────────────

  /// Records a user interaction as a taste signal, updating the user's
  /// tasteVector in Firestore.
  ///
  /// Call this fire-and-forget style — do not await in the UI path.
  ///
  /// [signalType] must be one of: 'visit', 'save', 'booking', 'post',
  /// 'like', 'dismiss'. Weights are applied server-side.
  ///
  /// [types] and [tags] should be canonical engine keys obtained via
  /// [RecommendationMappings.normalizeApiTypes] from the Places API response.
  ///
  /// [source] is a free-form label for debugging (e.g. 'camera', 'map',
  /// 'booking_confirmation').
  static Future<void> recordSignal({
    required String placeId,
    required String signalType,
    String? placeName,
    List<String> types = const [],
    List<String> tags = const [],
    String source = 'client',
  }) async {
    try {
      await _fn('recordTasteSignal').call({
        'placeId': placeId,
        'signalType': signalType,
        if (placeName != null) 'placeName': placeName,
        'types': types,
        'tags': tags,
        'source': source,
      });
    } catch (e) {
      // Signals are best-effort — a missed signal just means slightly less
      // personalisation, not a broken user experience.
      debugPrint('RecommendationService.recordSignal: $e');
    }
  }

  // ── Recommendations ────────────────────────────────────────────────────────

  /// Scores and ranks [candidates] for the current user and returns an ordered
  /// list with reasons.
  ///
  /// [candidates] are Maps built from Google Places API results. Each must
  /// contain: placeId, name, types[], tags[], rating, userRatingCount, lat, lng.
  ///
  /// [context] controls scoring weight distribution:
  ///   - 'solo'    → taste-heavy (40%) — for trip planning
  ///   - 'nearby'  → proximity-heavy (30%) — for map nearby panel
  ///   - 'similar' → collab-heavy (30%) — for "similar places" after a visit
  ///   - 'home'    → balanced — for home feed carousel
  ///
  /// [weather] is passed to the engine so outdoor places are penalised during
  /// extreme heat / sandstorm conditions. Safe to omit if unavailable.
  ///
  /// Returns null on error so callers can fall back to unranked display.
  static Future<RecommendationResult?> recommendPlaces({
    required List<Map<String, dynamic>> candidates,
    required String context,
    double? userLat,
    double? userLng,
    int limit = 10,
    bool excludeSeen = true,
    WeatherContext? weather,
  }) async {
    if (candidates.isEmpty) return null;
    try {
      final result = await _fn('recommendPlaces').call({
        'candidates': candidates,
        'context': context,
        'limit': limit,
        'excludeSeen': excludeSeen,
        if (userLat != null) 'userLat': userLat,
        if (userLng != null) 'userLng': userLng,
        if (weather != null) 'weatherContext': weather.toEngineContext(),
      });
      return RecommendationResult.fromMap(
        Map<String, dynamic>.from(result.data as Map),
      );
    } catch (e) {
      debugPrint('RecommendationService.recommendPlaces: $e');
      return null;
    }
  }

  // ── Quiz integration ───────────────────────────────────────────────────────

  /// Applies quiz answers to the user's tasteVector in a single batched write.
  ///
  /// [answers] should be built with
  /// `RecommendationMappings.answersFromSelections()` — each entry is a Map
  /// with keys 'optionId', 'types', and 'tags'.
  ///
  /// Call this when the user taps "Finish" at the end of the quiz flow, before
  /// navigating to the result screen.
  static Future<void> applyQuizAnswers(
    List<Map<String, dynamic>> answers,
  ) async {
    if (answers.isEmpty) return;
    try {
      await _fn('applyQuizAnswers').call({'answers': answers});
    } catch (e) {
      debugPrint('RecommendationService.applyQuizAnswers: $e');
    }
  }

  // ── Cold-start bootstrap ───────────────────────────────────────────────────

  /// Bootstraps the tasteVector from existing Firestore data — saved places,
  /// tour bookings, and community posts with a locationId.
  ///
  /// Rate-limited server-side to 1 call per user per day. Safe to call
  /// speculatively; if already run today the server silently rejects and we
  /// just log the rate-limit error.
  ///
  /// Recommended timing: call once immediately after the first quiz completion
  /// (check that `users/{uid}.quizCompletedAt` was previously null).
  static Future<void> warmStart() async {
    try {
      await _fn('warmStartTasteVector').call({});
    } catch (e) {
      // HttpsError code 'resource-exhausted' means rate limit hit — not a bug.
      debugPrint('RecommendationService.warmStart: $e');
    }
  }
}
