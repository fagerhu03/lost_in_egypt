import '../entities/trip_plan_entity.dart';

abstract class TripPlannerRepository {
  String buildPrompt(TripPlanEntity plan);
} 