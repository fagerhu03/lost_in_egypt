import '../repositories/home_repository.dart';

class SyncLiveEventsUseCase {
  final HomeRepository repository;

  SyncLiveEventsUseCase(this.repository);

  Future<void> call() async {
    return await repository.syncLiveEvents();
  }
}
