class TripPlanEntity {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final List<String> interests;
  final List<String> areas;
  final List<String> tripTimes;
  final double minBudget;
  final double maxBudget;

  const TripPlanEntity({
    this.fromDate,
    this.toDate,
    this.location,
    this.locationLat,
    this.locationLng,
    this.interests = const [],
    this.areas = const [],
    this.tripTimes = const [],
    this.minBudget = 1000,
    this.maxBudget = 5000,
  });

  TripPlanEntity copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? location,
    double? locationLat,
    double? locationLng,
    List<String>? interests,
    List<String>? areas,
    List<String>? tripTimes,
    double? minBudget,
    double? maxBudget,
  }) {
    return TripPlanEntity(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      location: location ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      interests: interests ?? this.interests,
      areas: areas ?? this.areas,
      tripTimes: tripTimes ?? this.tripTimes,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
    );
  }
}