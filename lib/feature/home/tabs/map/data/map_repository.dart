import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/data/models/map_item_models.dart';

class MapRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MapItem>> fetchFeaturedMapItems({int limit = 80}) async {
    const featuredTags = ['recommended', 'featured', 'top_pick', 'must_see'];
    return _fetchByTags(featuredTags, limit: limit);
  }

  /// ✅ "All" but limited for performance
  Future<List<MapItem>> fetchAllMapItemsLimited({int limit = 500}) async {
    try {
      final results = await Future.wait([
        _firestore.collection('places').limit(limit).get(),
        _firestore.collection('events').limit(limit).get(),
      ]);

      final placesSnapshot = results[0];
      final eventsSnapshot = results[1];

      final List<MapItem> allItems = [];

      for (final doc in placesSnapshot.docs) {
        allItems.add(PlaceModel.fromMap(doc.data(), doc.id));
      }
      for (final doc in eventsSnapshot.docs) {
        allItems.add(EventModel.fromMap(doc.data(), doc.id));
      }

      return allItems;
    } catch (e) {
      // ignore: avoid_print
      print("❌ MapRepo Error (all): $e");
      return [];
    }
  }

  Future<List<MapItem>> fetchByUiCategory(String uiCategoryId, {int limit = 250}) async {
    // ✅ New: All
    if (uiCategoryId == 'all') {
      return fetchAllMapItemsLimited(limit: limit);
    }

    final tags = _tagsForUiCategory(uiCategoryId);
    if (tags.isEmpty) return fetchFeaturedMapItems(limit: limit);

    return _fetchByTags(tags, limit: limit);
  }

  // ----------------------------
  // Internal helpers
  // ----------------------------
  List<String> _tagsForUiCategory(String id) {
    switch (id) {
      case 'recommended':
        return const ['recommended', 'featured', 'top_pick', 'must_see'];

      case 'historic':
        return const ['historic', 'pyramid', 'temple', 'unesco', 'old_kingdom', 'middle_kingdom'];

      case 'museum':
        return const ['museum'];

      case 'market':
        return const ['market', 'shopping', 'bazaar', 'souq'];

      case 'restaurants':
        return const ['restaurant', 'food', 'dining'];

      case 'nightlife':
        return const ['nightlife', 'bar', 'club', 'music', 'jazz', 'opera'];

      case 'event':
        return const ['event'];

      default:
        return const [];
    }
  }

  Future<List<MapItem>> _fetchByTags(List<String> tags, {required int limit}) async {
    try {
      final results = await Future.wait([
        _firestore
            .collection('places')
            .where('tags', arrayContainsAny: tags)
            .limit(limit)
            .get(),
        _firestore
            .collection('events')
            .where('tags', arrayContainsAny: tags)
            .limit(limit)
            .get(),
      ]);

      final placesSnapshot = results[0];
      final eventsSnapshot = results[1];

      final List<MapItem> allItems = [];

      for (final doc in placesSnapshot.docs) {
        allItems.add(PlaceModel.fromMap(doc.data(), doc.id));
      }
      for (final doc in eventsSnapshot.docs) {
        allItems.add(EventModel.fromMap(doc.data(), doc.id));
      }

      return allItems;
    } catch (e) {
      // ignore: avoid_print
      print("❌ MapRepo Error (tags): $e");
      return [];
    }
  }
}