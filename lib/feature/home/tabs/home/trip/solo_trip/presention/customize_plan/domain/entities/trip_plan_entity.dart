class TripPlanEntity {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? location;
  final List<String> interests;
  final List<String> areas;
  final String? tripTime;
  final double minBudget;
  final double maxBudget;

  const TripPlanEntity({
    this.fromDate,
    this.toDate,
    this.location,
    this.interests = const [],
    this.areas = const [],
    this.tripTime,
    this.minBudget = 1000,
    this.maxBudget = 5000,
  });

  TripPlanEntity copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? location,
    List<String>? interests,
    List<String>? areas,
    String? tripTime,
    double? minBudget,
    double? maxBudget,
  }) {
    return TripPlanEntity(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      areas: areas ?? this.areas,
      tripTime: tripTime ?? this.tripTime,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
    );
  }
}