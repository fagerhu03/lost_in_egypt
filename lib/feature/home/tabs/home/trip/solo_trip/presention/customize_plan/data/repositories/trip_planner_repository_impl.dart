import '../../domain/entities/trip_plan_entity.dart';
import '../../domain/repositories/trip_planner_repository.dart';

class TripPlannerRepositoryImpl implements TripPlannerRepository {
  @override
  String buildPrompt(TripPlanEntity plan) {
    final from = plan.fromDate?.toString().split(' ').first ?? 'Not selected';
    final to = plan.toDate?.toString().split(' ').first ?? 'Not selected';
    final location = plan.location?.trim().isNotEmpty == true
        ? plan.location!.trim()
        : 'Not selected';
    final interests =
    plan.interests.isEmpty ? 'Not selected' : plan.interests.join(', ');
    final areas = plan.areas.isEmpty ? 'Not selected' : plan.areas.join(', ');
    final tripTime = plan.tripTime ?? 'Not selected';

    return '''
Create a personalized travel plan in Egypt based on these user preferences:

- Date range: $from to $to
- Current location or preferred start point: $location
- Interests: $interests
- Areas to visit: $areas
- Preferred time: $tripTime
- Budget range: ${plan.minBudget.toInt()} to ${plan.maxBudget.toInt()} EGP

Return a practical itinerary with suggestions that match the selected interests, timing, and budget.
''';
  }
}