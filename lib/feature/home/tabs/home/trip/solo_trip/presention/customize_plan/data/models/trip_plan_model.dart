import '../../domain/entities/trip_plan_entity.dart';

class TripPlanModel extends TripPlanEntity {
  const TripPlanModel({
    super.fromDate,
    super.toDate,
    super.location,
    super.locationLat,
    super.locationLng,
    super.interests,
    super.areas,
    super.tripTimes,
    super.minBudget,
    super.maxBudget,
  });

  factory TripPlanModel.fromEntity(TripPlanEntity entity) {
    return TripPlanModel(
      fromDate: entity.fromDate,
      toDate: entity.toDate,
      location: entity.location,
      locationLat: entity.locationLat,
      locationLng: entity.locationLng,
      interests: entity.interests,
      areas: entity.areas,
      tripTimes: entity.tripTimes,
      minBudget: entity.minBudget,
      maxBudget: entity.maxBudget,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'location': location,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'interests': interests,
      'areas': areas,
      'tripTimes': tripTimes,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
    };
  }
}