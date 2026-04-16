import '../entities/trip_plan_entity.dart';
import '../repositories/trip_planner_repository.dart';

class BuildTripPromptUseCase {
  final TripPlannerRepository repository;

  BuildTripPromptUseCase(this.repository);

  String call(TripPlanEntity plan) {
    return repository.buildPrompt(plan);
  }
}