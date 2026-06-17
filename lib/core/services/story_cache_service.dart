import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lost_in_egypt/core/services/ai_storyteller_service.dart';

/// Firestore-backed cache for AI landmark stories.
/// Cache key: slugified landmark name. TTL: 90 days.
/// Falls back to Cloud Function on miss.
class StoryCacheService {
  StoryCacheService._();
  static final StoryCacheService instance = StoryCacheService._();

  // In-memory layer so repeated opens within a session are instant.
  final Map<String, String> _memCache = {};

  static const _ttlDays = 90;

  String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').trim();

  Future<String> getStory(String landmarkName, {String locale = 'en'}) async {
    // English keeps the original bare-slug key (no cache invalidation); Arabic
    // gets its own `_ar` namespace so the two languages never collide.
    final slug =
        locale == 'ar' ? '${_slug(landmarkName)}_ar' : _slug(landmarkName);

    // 1. Memory hit
    if (_memCache.containsKey(slug)) return _memCache[slug]!;

    // 2. Firestore hit (within TTL)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('place_stories')
          .doc(slug)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final cachedAt = (data['cachedAt'] as Timestamp?)?.toDate();
        final story = data['story'] as String?;
        if (story != null && cachedAt != null) {
          final age = DateTime.now().difference(cachedAt).inDays;
          if (age < _ttlDays) {
            _memCache[slug] = story;
            return story;
          }
        }
      }
    } catch (e) {
      debugPrint('StoryCacheService: Firestore read failed: $e');
    }

    // 3. Cloud Function
    final story =
        await AIStorytellerService.getLandmarkStory(landmarkName, locale: locale);

    // Don't cache an empty response — let the next call retry
    if (story.isEmpty) return story;

    // 4. Write-through
    _memCache[slug] = story;
    try {
      await FirebaseFirestore.instance
          .collection('place_stories')
          .doc(slug)
          .set({'story': story, 'cachedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('StoryCacheService: Firestore write failed: $e');
    }

    return story;
  }
}
