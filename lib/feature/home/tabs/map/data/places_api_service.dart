import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service that calls Google Places API (New) — Text Search.
/// Uses Text Search instead of Nearby Search to cover all of Egypt
/// (Nearby Search has a 50km max radius limit).
class PlacesApiService {
  final String apiKey;

  PlacesApiService({required this.apiKey});

  /// Master kill-switch. When `true`, every billed entry point short-circuits
  /// without hitting `places.googleapis.com`. Set from `main.dart` via
  /// `PLACES_API_DISABLED=true` in `.env`. Used during development to test
  /// non-Places features without burning quota / billing.
  ///
  /// Behavior when on:
  ///   • `searchMultipleQueries` THROWS → `MapRepository` falls through its
  ///     cache chain to the bundled asset (500 landmarks still render).
  ///   • All other entry points return empty/null gracefully.
  static bool disabled = false;

  static Never _throwBlocked(String method) {
    debugPrint('🛑 PLACES API BLOCKED ($method) — kill-switch is on');
    throw StateError('PlacesApiService disabled via PLACES_API_DISABLED');
  }

  static void _logBlocked(String method) {
    debugPrint('🛑 PLACES API BLOCKED ($method) — kill-switch is on');
  }

  // ── Global API call tracker ──
  static int _totalApiCalls = 0;
  static int get totalApiCalls => _totalApiCalls;

  static void _logApiCall(String method, String detail) {
    _totalApiCalls++;
    final caller = _getCaller();
    debugPrint('');
    debugPrint('💰💰💰 PLACES API CALL #$_totalApiCalls 💰💰💰');
    debugPrint('   Method : $method');
    debugPrint('   Detail : $detail');
    debugPrint('   Caller : $caller');
    debugPrint('');
  }

  /// Walks up the stack to find the first caller outside PlacesApiService
  static String _getCaller() {
    try {
      final stack = StackTrace.current.toString().split('\n');
      for (final line in stack) {
        if (!line.contains('PlacesApiService') &&
            !line.contains('_logApiCall') &&
            !line.contains('_getCaller') &&
            line.trim().isNotEmpty) {
          return line.trim();
        }
      }
    } catch (_) {}
    return 'unknown';
  }
  /// Searches for places in Egypt using the Text Search (New) API.
  ///
  /// [query] — text query like "museums in Egypt" or "historical temples Egypt"
  /// [includedType] — optional single type filter, e.g. 'museum'
  /// [maxResultCount] — max results (1-20)
  /// [bulkMode] — when true, omits `reviews` and `editorialSummary` from the
  ///   field mask. This drops the SKU from Enterprise+Atmosphere ($0.040/call)
  ///   to Enterprise ($0.035/call) — meaningful on a 54-query cold-start batch.
  ///   `currentOpeningHours` is preserved so the "Open Now" map filter still
  ///   works. Reviews and description are lazy-loaded in the detail sheet
  ///   via `getPlaceDetails` (Firestore-cached after first fetch).
  Future<List<Map<String, dynamic>>> textSearch({
    required String query,
    String? includedType,
    int maxResultCount = 20,
    bool bulkMode = false,
  }) async {
    const url = 'https://places.googleapis.com/v1/places:searchText';

    final fieldMask = [
      'places.id',
      'places.displayName',
      'places.location',
      'places.primaryType',
      'places.types',
      'places.rating',
      'places.userRatingCount',
      'places.formattedAddress',
      'places.photos',
      'places.priceLevel',
      'places.currentOpeningHours',
      if (!bulkMode) 'places.editorialSummary',
      if (!bulkMode) 'places.reviews',
    ].join(',');

    final bodyMap = <String, dynamic>{
      'textQuery': query,
      'maxResultCount': maxResultCount,
      'languageCode': 'en',
    };

    if (includedType != null) {
      bodyMap['includedType'] = includedType;
    }

    final body = jsonEncode(bodyMap);

    if (disabled) {
      _logBlocked('textSearch query="$query"');
      return [];
    }

    if (kDebugMode) {
      _logApiCall('textSearch', 'query="$query", type=$includedType');
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': fieldMask,
        },
        body: body,
      );

      if (kDebugMode) debugPrint('📡 Places API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final places = data['places'] as List<dynamic>? ?? [];
        if (kDebugMode) debugPrint('✅ Places API returned ${places.length} results for: "$query"');
        return places.cast<Map<String, dynamic>>();
      } else {
        if (kDebugMode) debugPrint('❌ Places API error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Places API network error: $e');
      return [];
    }
  }

  /// Cheap "find place by name" — returns just the lat/lng of the top match,
  /// using a minimal field mask (Basic SKU only). Used to backfill coordinates
  /// for AI-generated trip stops where the model omitted them.
  ///
  /// Returns null when no match found or the request failed.
  Future<({double lat, double lng})?> findPlaceLocation(String query) async {
    final cached = _locationCache[query];
    if (cached != null) return cached;

    if (disabled) {
      _logBlocked('findPlaceLocation query="$query"');
      return null;
    }

    const url = 'https://places.googleapis.com/v1/places:searchText';
    // Basic field mask only — keeps cost at $0.017/call (vs $0.032 for Advanced)
    const fieldMask = 'places.location';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': fieldMask,
        },
        body: jsonEncode({
          'textQuery': query,
          'maxResultCount': 1,
          'languageCode': 'en',
          'regionCode': 'EG',
        }),
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List<dynamic>? ?? const [];
      if (places.isEmpty) return null;
      final loc = (places.first as Map<String, dynamic>)['location']
          as Map<String, dynamic>?;
      final lat = (loc?['latitude'] as num?)?.toDouble();
      final lng = (loc?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final result = (lat: lat, lng: lng);
      _locationCache[query] = result;
      return result;
    } catch (_) {
      return null;
    }
  }

  // Memory cache so repeated lookups in a session don't re-bill.
  static final Map<String, ({double lat, double lng})> _locationCache = {};

  /// Full "find place by name" — returns the top match with the rich fields the
  /// place-detail sheet needs (id, rating, photos, address, primary type).
  /// Advanced SKU ($0.032/call) — call this on-demand (e.g. when the user
  /// taps "View on Map") rather than for every stop, and the cache makes
  /// repeated taps free.
  ///
  /// Returns the raw Places API place map (same shape as `textSearch`).
  Future<Map<String, dynamic>?> findPlaceFull(String query) async {
    final cached = _fullCache[query];
    if (cached != null) return cached;

    if (disabled) {
      _logBlocked('findPlaceFull query="$query"');
      return null;
    }

    const url = 'https://places.googleapis.com/v1/places:searchText';
    final fieldMask = [
      'places.id',
      'places.displayName',
      'places.location',
      'places.formattedAddress',
      'places.primaryType',
      'places.types',
      'places.rating',
      'places.userRatingCount',
      'places.photos',
      'places.editorialSummary',
      'places.currentOpeningHours',
      'places.reviews',
    ].join(',');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': fieldMask,
        },
        body: jsonEncode({
          'textQuery': query,
          'maxResultCount': 1,
          'languageCode': 'en',
          'regionCode': 'EG',
        }),
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List<dynamic>? ?? const [];
      if (places.isEmpty) return null;
      final place = Map<String, dynamic>.from(places.first as Map);
      _fullCache[query] = place;
      return place;
    } catch (_) {
      return null;
    }
  }

  static final Map<String, Map<String, dynamic>> _fullCache = {};

  /// Fetches places for multiple search queries in chunks to avoid rate limits and socket crashes.
  /// Returns a flat list of all results, de-duplicated by place ID.
  Future<List<Map<String, dynamic>>> searchMultipleQueries(
    List<PlacesSearchQuery> queries,
  ) async {
    if (disabled) {
      // Throw so MapRepository's try/catch falls through to the bundled-asset
      // path (500 landmarks). Returning [] would corrupt the disk cache by
      // saving an empty list on top of any prior valid snapshot.
      _throwBlocked('searchMultipleQueries (${queries.length} queries)');
    }

    final allPlaces = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    const int chunkSize = 5;

    for (int i = 0; i < queries.length; i += chunkSize) {
      final end = (i + chunkSize < queries.length) ? i + chunkSize : queries.length;
      final chunk = queries.sublist(i, end);

      if (kDebugMode) debugPrint('📦 Fetching queries ${i + 1} to $end of ${queries.length}...');

      final futures = <Future<List<Map<String, dynamic>>>>[];
      for (final q in chunk) {
        futures.add(textSearch(
          query: q.query,
          includedType: q.includedType,
          // Bulk mode drops reviews + editorialSummary — those are lazy-loaded
          // on tap via getPlaceDetails so the 54-query startup batch can
          // afford the leaner SKU.
          bulkMode: true,
        ));
      }

      final results = await Future.wait(futures);

      for (final list in results) {
        for (final place in list) {
          final id = place['id'] as String? ?? '';
          if (id.isNotEmpty && seenIds.add(id)) {
            allPlaces.add(place);
          }
        }
      }
      
      // Delay to avoid overwhelming sockets and rate limits
      if (end < queries.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (kDebugMode) debugPrint('📦 Total unique places from API: ${allPlaces.length}');
    return allPlaces;
  }

  // SharedPreferences-backed cache for nearbySearch. SOS results don't change
  // hour-to-hour (hospitals, police stations, fire stations) — a 7-day TTL
  // bucketed on a coarse ~1 km lat/lng grid is more than enough. Without this
  // cache, every SOS category re-tap re-bills.
  static const int _nearbyCacheTtlDays = 7;
  static const String _nearbyCacheKeyPrefix = 'places_nearby_v1_';

  String _nearbyCacheKey({
    required double lat,
    required double lng,
    required List<String> includedTypes,
    required double radiusMeters,
    required int maxResultCount,
  }) {
    // 2 decimal places ≈ 1.1 km grid at Egypt's latitude — coarse enough that
    // nudging the device a few hundred metres still hits the same cell.
    final latKey = lat.toStringAsFixed(2);
    final lngKey = lng.toStringAsFixed(2);
    final typesKey = (List<String>.from(includedTypes)..sort()).join('|');
    return '$_nearbyCacheKeyPrefix${typesKey}_${latKey}_$lngKey'
        '_r${radiusMeters.toInt()}_n$maxResultCount';
  }

  /// Searches for places near a specific coordinate within [radiusMeters].
  ///
  /// [lat] / [lng] — centre of the search circle
  /// [includedTypes] — Places API type strings, e.g. `['police', 'hospital']`
  /// [radiusMeters] — search radius (max 50 000 m)
  /// [maxResultCount] — max results (1–20)
  Future<List<Map<String, dynamic>>> nearbySearch({
    required double lat,
    required double lng,
    required List<String> includedTypes,
    double radiusMeters = 5000,
    int maxResultCount = 5,
  }) async {
    final cacheKey = _nearbyCacheKey(
      lat: lat,
      lng: lng,
      includedTypes: includedTypes,
      radiusMeters: radiusMeters,
      maxResultCount: maxResultCount,
    );

    // SharedPreferences cache lookup. Payload is { 'cachedAt': iso8601,
    // 'results': <api-places-array> }. Failures fall through to the API.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
        if (cachedAt != null &&
            DateTime.now().difference(cachedAt).inDays <
                _nearbyCacheTtlDays) {
          final list = (decoded['results'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          return list;
        }
      }
    } catch (_) {}

    if (disabled) {
      _logBlocked('nearbySearch lat=$lat lng=$lng types=$includedTypes');
      return [];
    }

    const url = 'https://places.googleapis.com/v1/places:searchNearby';

    final fieldMask = [
      'places.id',
      'places.displayName',
      'places.location',
      'places.formattedAddress',
      'places.internationalPhoneNumber',
      'places.primaryType',
    ].join(',');

    final body = jsonEncode({
      'includedTypes': includedTypes,
      'maxResultCount': maxResultCount,
      'languageCode': 'en',
      'locationRestriction': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusMeters,
        },
      },
    });

    if (kDebugMode) {
      _logApiCall('nearbySearch', 'lat=$lat, lng=$lng, types=$includedTypes, radius=$radiusMeters');
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': fieldMask,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['places'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        unawaited(_persistNearbyToPrefs(cacheKey, results));
        return results;
      }
      debugPrint('❌ Nearby search error ${response.statusCode}: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ Nearby search exception: $e');
      return [];
    }
  }

  Future<void> _persistNearbyToPrefs(
    String key,
    List<Map<String, dynamic>> results,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({
          'cachedAt': DateTime.now().toIso8601String(),
          'results': results,
        }),
      );
    } catch (_) {}
  }

  static final Map<String, Map<String, dynamic>> _detailsCache = {};

  // Firestore-backed details cache. Avoids re-billing per app session for the
  // same place — a tapped location chip in a community post would otherwise
  // hit the API on every fresh app launch since the in-memory cache resets.
  // 30-day TTL because place details (rating, reviews) drift slowly.
  static const int _detailsFirestoreTtlDays = 30;

  /// Fetches full details for a single place by its Places API place ID.
  /// Resolution order: memory → Firestore (≤30 days old) → Places API.
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    if (_detailsCache.containsKey(placeId)) return _detailsCache[placeId];

    // Firestore cache lookup. Stored as { 'data': <api-json>, 'cachedAt': ts }
    // under place_details/{placeId}. Failure is silent — we just fall through
    // to the API call so the place still resolves.
    try {
      final doc = await FirebaseFirestore.instance
          .collection('place_details')
          .doc(placeId)
          .get();
      if (doc.exists) {
        final raw = doc.data();
        final cachedAt = (raw?['cachedAt'] as Timestamp?)?.toDate();
        final payload = raw?['data'];
        if (cachedAt != null &&
            payload is Map &&
            DateTime.now().difference(cachedAt).inDays <
                _detailsFirestoreTtlDays) {
          final data = Map<String, dynamic>.from(payload);
          _detailsCache[placeId] = data;
          return data;
        }
      }
    } catch (_) {}

    if (disabled) {
      _logBlocked('getPlaceDetails placeId=$placeId');
      return null;
    }

    if (kDebugMode) {
      _logApiCall('getPlaceDetails', 'placeId=$placeId');
    }
    final fieldMask = [
      'id', 'displayName', 'location', 'formattedAddress',
      'rating', 'primaryType', 'types', 'photos',
      'editorialSummary', 'priceLevel', 'currentOpeningHours', 'reviews',
    ].join(',');

    try {
      final response = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/$placeId'),
        headers: {
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': fieldMask,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _detailsCache[placeId] = data;
        // Write-through to Firestore so other devices / future sessions skip
        // the API. Best-effort; never blocks the caller on failure.
        unawaited(_persistDetailsToFirestore(placeId, data));
        return data;
      }
    } catch (e) {
      debugPrint('❌ getPlaceDetails error: $e');
    }
    return null;
  }

  Future<void> _persistDetailsToFirestore(
    String placeId,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('place_details')
          .doc(placeId)
          .set({'data': data, 'cachedAt': Timestamp.now()});
    } catch (_) {}
  }

  /// Build a photo URL from a Places API photo resource name.
  static String buildPhotoUrl(String photoName, String apiKey, {int maxWidth = 800}) {
    return 'https://places.googleapis.com/v1/$photoName/media?maxWidthPx=$maxWidth&key=$apiKey';
  }
}

/// A search query descriptor for batch fetching.
class PlacesSearchQuery {
  final String query;
  final String? includedType;

  const PlacesSearchQuery({required this.query, this.includedType});
}
