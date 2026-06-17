import 'dart:math';

import '../../feature/home/tabs/home/data/models/map_item_models.dart';

/// Best-effort resolver from a synthetic place reference (AI-generated trip
/// stop, curated trip stop, etc.) to a real dataset entry with a stable
/// `placeId`, real category/tags, and accurate coordinates.
///
/// Why this exists: AI trip plans and curated trip definitions ship with only
/// a free-form name and AI-supplied coordinates. Recording recommendation
/// signals against `name.toLowerCase().replaceAll(' ', '_')` creates a parallel
/// universe of synthetic place IDs that never match the real Places API IDs —
/// breaking collab filtering, fragmenting `place_affinity`, and polluting the
/// per-user `soloPlanSeen` cap (200 entries). This resolver maps the synthetic
/// stop back to the real pin before signal-time so all of that just works.
///
/// Matching algorithm — proximity-first, content-word overlap:
///   1. Filter dataset to pins within 2 km of the synthetic coords (Haversine)
///   2. Exact normalised-title match → return immediately
///   3. ≥ 2 content-word overlap → best overlap score wins
///   4. 1 content-word overlap of ≥ 4 chars within 1 km → closest distance wins
///   5. Empty normalised titles (Arabic/Hebrew-only entries) are explicitly
///      skipped — `"".contains("")` is always `true` in Dart and would match
///      every empty-titled entry otherwise
///   6. No confident match → returns null; callers should keep the synthetic
///
/// Pulled out of map_screen.dart so active_tour_screen (and any future surface
/// that needs to resolve synthetic stops to real IDs) can reuse it.
class DatasetResolver {
  DatasetResolver._();

  /// Resolve by name + coords. Returns the matched `MapItem` from [dataset],
  /// or null when no confident match exists.
  static MapItem? resolve({
    required String name,
    required double lat,
    required double lng,
    required List<MapItem> dataset,
  }) {
    if (dataset.isEmpty) return null;
    final q = _normalizeTitle(name);
    if (q.isEmpty) return null;
    final qWords = _contentWords(q);

    MapItem? bestMulti;
    int bestMultiScore = 1;
    MapItem? bestSingle;
    double bestSingleDist = double.infinity;

    for (final item in dataset) {
      final dist = _haversineM(
          lat, lng, item.coordinate.latitude, item.coordinate.longitude);
      if (dist > 2000) continue;

      final t = _normalizeTitle(item.title);
      if (t.isEmpty) continue;
      if (t == q) return item;

      final overlap = qWords.intersection(_contentWords(t)).length;

      if (overlap >= 2 && overlap > bestMultiScore) {
        bestMultiScore = overlap;
        bestMulti = item;
      }

      if (overlap == 1 && dist <= 1000 && dist < bestSingleDist) {
        final word = qWords.intersection(_contentWords(t)).first;
        if (word.length >= 4) {
          bestSingleDist = dist;
          bestSingle = item;
        }
      }
    }

    return bestMulti ?? bestSingle;
  }

  /// Convenience overload — resolve an existing synthetic `MapItem`.
  static MapItem? resolveItem(MapItem synthetic, List<MapItem> dataset) =>
      resolve(
        name: synthetic.title,
        lat: synthetic.coordinate.latitude,
        lng: synthetic.coordinate.longitude,
        dataset: dataset,
      );

  /// Lower-case, alphanumeric-only, whitespace-collapsed.
  static String _normalizeTitle(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Words ≥3 chars that aren't common stop words. Strips "el", "al", "the",
  /// etc. so they don't inflate the overlap count.
  static Set<String> _contentWords(String normalized) {
    const stop = {
      'el', 'al', 'the', 'of', 'in', 'at', 'and', 'or', 'a', 'an',
      'by', 'to', 'for', 'abu', 'ibn', 'bab', 'dar',
    };
    return normalized
        .split(' ')
        .where((w) => w.length >= 3 && !stop.contains(w))
        .toSet();
  }

  static double _haversineM(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final p1 = lat1 * pi / 180, p2 = lat2 * pi / 180;
    final dp = (lat2 - lat1) * pi / 180, dl = (lng2 - lng1) * pi / 180;
    final a = sin(dp / 2) * sin(dp / 2) +
        cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
