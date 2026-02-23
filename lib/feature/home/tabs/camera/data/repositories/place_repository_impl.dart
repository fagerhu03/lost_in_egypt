import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/place_repository.dart';

/// Implementation of [PlaceRepository] using Firestore
class PlaceRepositoryImpl implements PlaceRepository {
  final FirebaseFirestore _firestore;

  PlaceRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> getPlaceByTitle(String title) async {
    try {
      final snapshot = await _firestore
          .collection("places")
          .where("title", isEqualTo: title)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first;
    } catch (e) {
      throw Exception('Failed to fetch place: $e');
    }
  }
}
