import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/data/models/map_item_models.dart'; // Import for MapItem, PlaceModel, EventModel

class MapRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch EVERYTHING (Events + Places) to show on the map
  Future<List<MapItem>> fetchAllMapItems() async {
    try {
      // 1. Run both queries in parallel
      final results = await Future.wait([
        _firestore.collection('places').get(),
        _firestore.collection('events').get(),
      ]);

      final placesSnapshot = results[0];
      final eventsSnapshot = results[1];

      List<MapItem> allItems = [];

      // 2. Convert PLACES (Permanent Landmarks)
      for (var doc in placesSnapshot.docs) {
        // We use the factory method we just created
        allItems.add(PlaceModel.fromMap(doc.data(), doc.id));
      }

      // 3. Convert EVENTS (Temporary Occurrences)
      for (var doc in eventsSnapshot.docs) {
        allItems.add(EventModel.fromMap(doc.data(), doc.id));
      }

      print("📍 MapRepo: Fetched ${allItems.length} total items for the map.");
      return allItems;
    } catch (e) {
      print("❌ MapRepo Error: $e");
      return []; // Return empty list on error so app doesn't crash
    }
  }
}