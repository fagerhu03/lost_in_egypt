import 'package:lost_in_egypt/feature/tours/domain/entities/tour_entity.dart';
import '../repositories/home_repository.dart';

class GetPopularToursStreamUseCase {
  final HomeRepository repository;

  GetPopularToursStreamUseCase(this.repository);

  Stream<List<TourEntity>> call(int limit) {
    return repository.getPopularToursStream(limit);
  }
}
