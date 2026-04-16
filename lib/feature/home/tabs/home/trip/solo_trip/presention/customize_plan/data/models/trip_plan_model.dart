import '../../domain/entities/trip_plan_entity.dart';

class TripPlanModel extends TripPlanEntity {
  const TripPlanModel({
    super.fromDate,
    super.toDate,
    super.location,
    super.interests,
    super.areas,
    super.tripTime,
    super.minBudget,
    super.maxBudget,
  });

  factory TripPlanModel.fromEntity(TripPlanEntity entity) {
    return TripPlanModel(
      fromDate: entity.fromDate,
      toDate: entity.toDate,
      location: entity.location,
      interests: entity.interests,
      areas: entity.areas,
      tripTime: entity.tripTime,
      minBudget: entity.minBudget,
      maxBudget: entity.maxBudget,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'location': location,
      'interests': interests,
      'areas': areas,
      'tripTime': tripTime,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
    };
  }
}