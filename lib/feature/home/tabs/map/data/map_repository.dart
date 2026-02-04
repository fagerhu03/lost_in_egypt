import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../home/data/models/map_item_models.dart';

class MapRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MapItem>> fetchFeaturedMapItems({int limit = 80}) async {
    debugPrint('📦 fetchFeaturedMapItems called (limit: $limit)');
    const featuredTags = ['recommended', 'featured', 'top_pick', 'must_see'];
    return _fetchByTags(featuredTags, limit: limit);
  }

  Future<List<MapItem>> fetchAllMapItemsLimited({int limit = 2000}) async {
    debugPrint('📦 fetchAllMapItemsLimited called (limit: $limit)');
    
    try {
      final results = await Future.wait([
        _firestore.collection('places').limit(limit).get(),
        _firestore.collection('events').limit(limit).get(),
      ]);

      final placesSnapshot = results[0];
      final eventsSnapshot = results[1];

      debugPrint('✅ Firestore returned:');
      debugPrint('   📁 places: ${placesSnapshot.docs.length} documents');
      debugPrint('   📁 events: ${eventsSnapshot.docs.length} documents');

      final List<MapItem> allItems = [];

      for (final doc in placesSnapshot.docs) {
        try {
          allItems.add(PlaceModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('   ❌ Error parsing place ${doc.id}: $e');
        }
      }
      
      for (final doc in eventsSnapshot.docs) {
        try {
          allItems.add(EventModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('   ❌ Error parsing event ${doc.id}: $e');
        }
      }

      debugPrint('📦 Returning ${allItems.length} total items');
      return allItems;
      
    } catch (e) {
      debugPrint('❌ MapRepo Error (all): $e');
      return [];
    }
  }

  Future<List<MapItem>> fetchByUiCategory(String uiCategoryId, {int limit = 500}) async {
    debugPrint('📦 fetchByUiCategory("$uiCategoryId", limit: $limit)');
    
    if (uiCategoryId == 'all') {
      return fetchAllMapItemsLimited(limit: limit);
    }

    final tags = _tagsForUiCategory(uiCategoryId);
    debugPrint('   → Tags for "$uiCategoryId": $tags');
    
    if (tags.isEmpty) {
      return fetchFeaturedMapItems(limit: limit);
    }

    return _fetchByTags(tags, limit: limit);
  }

  List<String> _tagsForUiCategory(String id) {
    switch (id) {
      case 'recommended':
        return const ['recommended', 'featured', 'top_pick', 'must_see'];
      case 'landmark':
        return const ['landmark', 'historic', 'pyramid', 'temple', 'unesco'];
      case 'historic':
        return const ['historic', 'pyramid', 'temple', 'unesco', 'old_kingdom', 'middle_kingdom'];
      case 'museum':
        return const ['museum'];
      case 'religious':
        return const ['religious', 'mosque', 'church', 'coptic', 'islamic'];
      case 'nature':
        return const ['nature', 'park', 'garden', 'beach', 'desert', 'oasis'];
      case 'shopping':
        return const ['market', 'shopping', 'bazaar', 'souq', 'mall'];
      case 'market':
        return const ['market', 'shopping', 'bazaar', 'souq'];
      case 'restaurant':
      case 'restaurants':
        return const ['restaurant', 'food', 'dining'];
      case 'nightlife':
        return const ['nightlife', 'bar', 'club', 'music', 'jazz', 'opera'];
      case 'event':
        return const ['event'];
      case 'tourism':
        return const ['tourism', 'attraction', 'sightseeing'];
      case 'hotel':
        return const ['hotel', 'accommodation', 'resort', 'hostel'];
      default:
        debugPrint('   ⚠️ Unknown category: $id');
        return const [];
    }
  }

  Future<List<MapItem>> _fetchByTags(List<String> tags, {required int limit}) async {
    debugPrint('📦 _fetchByTags($tags, limit: $limit)');
    
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

      debugPrint('✅ _fetchByTags returned:');
      debugPrint('   📁 places with tags: ${placesSnapshot.docs.length}');
      debugPrint('   📁 events with tags: ${eventsSnapshot.docs.length}');

      final List<MapItem> allItems = [];

      for (final doc in placesSnapshot.docs) {
        try {
          allItems.add(PlaceModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('   ❌ Error parsing place ${doc.id}: $e');
        }
      }
      
      for (final doc in eventsSnapshot.docs) {
        try {
          allItems.add(EventModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('   ❌ Error parsing event ${doc.id}: $e');
        }
      }

      debugPrint('📦 _fetchByTags returning ${allItems.length} items');
      return allItems;
      
    } catch (e) {
      debugPrint('❌ MapRepo Error (tags): $e');
      return [];
    }
  }
}