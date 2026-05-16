import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service that calls Google Places API (New) — Text Search.
/// Uses Text Search instead of Nearby Search to cover all of Egypt
/// (Nearby Search has a 50km max radius limit).
class PlacesApiService {
  final String apiKey;

  PlacesApiService({required this.apiKey});

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
  Future<List<Map<String, dynamic>>> textSearch({
    required String query,
    String? includedType,
    int maxResultCount = 20,
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
      'places.editorialSummary',
      'places.priceLevel',
      'places.currentOpeningHours',
      'places.reviews',
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
        return (data['places'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      debugPrint('❌ Nearby search error ${response.statusCode}: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ Nearby search exception: $e');
      return [];
    }
  }

  static final Map<String, Map<String, dynamic>> _detailsCache = {};

  /// Fetches full details for a single place by its Places API place ID.
  /// Results are cached in memory for the lifetime of the app session.
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    if (_detailsCache.containsKey(placeId)) return _detailsCache[placeId];

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
        return data;
      }
    } catch (e) {
      debugPrint('❌ getPlaceDetails error: $e');
    }
    return null;
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
