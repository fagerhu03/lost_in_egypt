import 'package:dartz/dartz.dart';
import 'package:lost_in_egypt/core/error/failures.dart';
import '../repositories/home_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class GetPopularPlacesUseCase {
  final HomeRepository repository;

  GetPopularPlacesUseCase(this.repository);

  Future<Either<Failure, List<PlaceModel>>> call(int limit) async {
    return await repository.getPopularPlaces(limit);
  }
}
