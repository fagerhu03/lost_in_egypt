import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service that calls Google Places API (New) — Text Search.
/// Uses Text Search instead of Nearby Search to cover all of Egypt
/// (Nearby Search has a 50km max radius limit).
class PlacesApiService {
  final String apiKey;

  PlacesApiService({required this.apiKey});

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

    debugPrint('🔍 Places API request: query="$query", type=$includedType');

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

      debugPrint('📡 Places API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final places = data['places'] as List<dynamic>? ?? [];
        debugPrint('✅ Places API returned ${places.length} results for: "$query"');
        return places.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ Places API error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Places API network error: $e');
      return [];
    }
  }

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

      debugPrint('📦 Fetching queries ${i + 1} to $end of ${queries.length}...');

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

    debugPrint('📦 Total unique places from API: ${allPlaces.length}');
    return allPlaces;
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
