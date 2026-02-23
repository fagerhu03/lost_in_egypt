import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract repository for place/landmark data operations
abstract class PlaceRepository {
  /// Fetches place details by name from Firestore
  /// Returns null if not found
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> getPlaceByTitle(String title);
}
