import '../repositories/home_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class GetEventsStreamUseCase {
  final HomeRepository repository;

  GetEventsStreamUseCase(this.repository);

  Stream<List<EventModel>> call(int limit) {
    return repository.getEventsStream(limit);
  }
}
