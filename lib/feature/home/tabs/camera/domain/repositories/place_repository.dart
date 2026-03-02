import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

/// Abstract repository for place/landmark data operations
abstract class PlaceRepository {
  /// Fetches place details by name from Google Places API
  /// Returns null if not found
  Future<PlaceModel?> getPlaceByTitle(String title);
}
