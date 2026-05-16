import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Fetches and caches a representative Places API photo URL for each curated
/// trip. Memory-cached for the session; Firestore-cached for 30 days so we
/// only hit the Places API once per trip per month.
class PlacePhotosService {
  PlacePhotosService._();
  static final PlacePhotosService instance = PlacePhotosService._();

  static const _cacheTtlDays = 30;
  static const _maxWidthPx = 900;

  final Map<String, String?> _memCache = {};

  String get _apiKey => dotenv.env['MAPS_API_KEY'] ?? '';

  /// Returns a photo URL for [tripId], using [searchQuery] to look it up.
  ///
  /// Resolution order: memory → Firestore (≤30 days old) → Places API.
  Future<String?> getPhotoUrl(String tripId, String searchQuery) async {
    if (_memCache.containsKey(tripId)) return _memCache[tripId];

    // Firestore cache
    try {
      final doc = await FirebaseFirestore.instance
          .collection('place_photos')
          .doc(tripId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final cachedAt = (data['cachedAt'] as Timestamp?)?.toDate();
        if (cachedAt != null &&
            DateTime.now().difference(cachedAt).inDays < _cacheTtlDays) {
          final url = data['url'] as String?;
          _memCache[tripId] = url;
          return url;
        }
      }
    } catch (_) {}

    // Fetch from Places API
    final url = await _fetchPhotoUrl(searchQuery);
    _memCache[tripId] = url;

    if (url != null) {
      try {
        await FirebaseFirestore.instance
            .collection('place_photos')
            .doc(tripId)
            .set({'url': url, 'cachedAt': Timestamp.now()});
      } catch (_) {}
    }

    return url;
  }

  Future<String?> _fetchPhotoUrl(String query) async {
    if (_apiKey.isEmpty) return null;

    try {
      const endpoint = 'https://places.googleapis.com/v1/places:searchText';
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask': 'places.photos',
            },
            body: jsonEncode({
              'textQuery': query,
              'maxResultCount': 1,
              'languageCode': 'en',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List? ?? [];
      if (places.isEmpty) return null;

      final photos =
          (places.first as Map<String, dynamic>)['photos'] as List? ?? [];
      if (photos.isEmpty) return null;

      final photoName =
          (photos.first as Map<String, dynamic>)['name'] as String?;
      if (photoName == null) return null;

      // Step 2: resolve the photo name into a real CDN URL.
      // skipHttpRedirect=true returns JSON { "photoUri": "https://lh3..." }
      // instead of a 302 redirect — we cache that stable CDN URL.
      final mediaUri = Uri.parse(
        'https://places.googleapis.com/v1/$photoName/media'
        '?key=$_apiKey'
        '&maxWidthPx=$_maxWidthPx'
        '&skipHttpRedirect=true',
      );
      final mediaRes =
          await http.get(mediaUri).timeout(const Duration(seconds: 10));
      if (mediaRes.statusCode != 200) return null;

      final mediaData =
          jsonDecode(mediaRes.body) as Map<String, dynamic>;
      return mediaData['photoUri'] as String?;
    } catch (e) {
      debugPrint('PlacePhotosService: fetch failed — $e');
      return null;
    }
  }
}
