import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/places_api_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/camera/domain/repositories/place_repository.dart';

/// Implementation of [PlaceRepository] using Google Places API
class PlaceRepositoryImpl implements PlaceRepository {
  final PlacesApiService _placesApiService;
  final String _apiKey;

  PlaceRepositoryImpl({
    required PlacesApiService placesApiService,
    required String apiKey,
  })  : _placesApiService = placesApiService,
        _apiKey = apiKey;

  @override
  Future<PlaceModel?> getPlaceByTitle(String title) async {
    try {
      final results = await _placesApiService.textSearch(
        query: title,
        maxResultCount: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      // Convert the raw JSON response to our model format
      return PlaceModel.fromPlacesApi(results.first, _apiKey);
    } catch (e) {
      throw Exception('Failed to fetch place details. Please check your connection.');
    }
  }
}
