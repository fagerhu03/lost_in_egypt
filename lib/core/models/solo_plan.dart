import 'package:cloud_firestore/cloud_firestore.dart';

enum SoloPlanStatus { saved, active, completed }

class SavedPlanStop {
  final String name;
  final String placeType;
  final String estimatedDuration;
  final String? notes;
  final double? lat;
  final double? lng;
  final bool completed;

  const SavedPlanStop({
    required this.name,
    required this.placeType,
    required this.estimatedDuration,
    this.notes,
    this.lat,
    this.lng,
    this.completed = false,
  });

  bool get hasCoordinates => lat != null && lng != null;

  SavedPlanStop copyWith({bool? completed}) => SavedPlanStop(
        name: name,
        placeType: placeType,
        estimatedDuration: estimatedDuration,
        notes: notes,
        lat: lat,
        lng: lng,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'placeType': placeType,
        'estimatedDuration': estimatedDuration,
        if (notes != null) 'notes': notes,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'completed': completed,
      };

  factory SavedPlanStop.fromMap(Map<String, dynamic> m) => SavedPlanStop(
        name: m['name'] as String? ?? '',
        placeType: m['placeType'] as String? ?? 'place',
        estimatedDuration: m['estimatedDuration'] as String? ?? '',
        notes: m['notes'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        completed: m['completed'] as bool? ?? false,
      );
}

/// Inter-city travel between days (e.g. Cairo → Luxor by sleeper train).
/// Optional: same-city consecutive days have no transit.
class SavedPlanTransit {
  final String from;
  final String to;
  final String mode;
  final String duration;
  final String approxCost;
  final String tip;

  const SavedPlanTransit({
    required this.from,
    required this.to,
    required this.mode,
    required this.duration,
    required this.approxCost,
    required this.tip,
  });

  Map<String, dynamic> toMap() => {
        'from': from,
        'to': to,
        'mode': mode,
        'duration': duration,
        'approxCost': approxCost,
        'tip': tip,
      };

  factory SavedPlanTransit.fromMap(Map<String, dynamic> m) => SavedPlanTransit(
        from: m['from'] as String? ?? '',
        to: m['to'] as String? ?? '',
        mode: m['mode'] as String? ?? '',
        duration: m['duration'] as String? ?? '',
        approxCost: m['approxCost'] as String? ?? '',
        tip: m['tip'] as String? ?? '',
      );
}

class SavedPlanDay {
  final int dayNumber;
  final String label;
  final List<SavedPlanStop> stops;
  final SavedPlanTransit? transit;

  const SavedPlanDay({
    required this.dayNumber,
    required this.label,
    required this.stops,
    this.transit,
  });

  int get completedCount => stops.where((s) => s.completed).length;
  int get totalCount => stops.length;
  bool get isComplete => completedCount == totalCount && totalCount > 0;

  SavedPlanStop? get nextIncompleteStop =>
      stops.where((s) => !s.completed).firstOrNull;

  SavedPlanDay copyWithStop(int stopIndex, bool completed) {
    final updated = List<SavedPlanStop>.from(stops);
    updated[stopIndex] = updated[stopIndex].copyWith(completed: completed);
    return SavedPlanDay(
      dayNumber: dayNumber,
      label: label,
      stops: updated,
      transit: transit,
    );
  }

  Map<String, dynamic> toMap() => {
        'dayNumber': dayNumber,
        'label': label,
        'stops': stops.map((s) => s.toMap()).toList(),
        if (transit != null) 'transit': transit!.toMap(),
      };

  factory SavedPlanDay.fromMap(Map<String, dynamic> m) => SavedPlanDay(
        dayNumber: m['dayNumber'] as int? ?? 1,
        label: m['label'] as String? ?? 'Day 1',
        transit: m['transit'] is Map
            ? SavedPlanTransit.fromMap(
                Map<String, dynamic>.from(m['transit'] as Map))
            : null,
        stops: (m['stops'] as List<dynamic>? ?? [])
            .map((s) => SavedPlanStop.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList(),
      );
}

class SavedPlan {
  final String id;
  final String title;
  final String tagline;

  /// 'curated' or 'custom'
  final String type;

  /// Set when [type] == 'curated', references the original trip id.
  final String? curatedTripId;

  final SoloPlanStatus status;
  final List<SavedPlanDay> days;
  final String estimatedBudget;
  final List<String> areas;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const SavedPlan({
    required this.id,
    required this.title,
    required this.tagline,
    required this.type,
    this.curatedTripId,
    required this.status,
    required this.days,
    required this.estimatedBudget,
    required this.areas,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  int get totalStops => days.fold(0, (acc, d) => acc + d.stops.length);
  int get completedStops =>
      days.fold(0, (acc, d) => acc + d.completedCount);
  double get progress =>
      totalStops == 0 ? 0 : completedStops / totalStops;

  /// Returns the next incomplete stop across all days.
  SavedPlanStop? get nextIncompleteStop {
    for (final day in days) {
      final s = day.nextIncompleteStop;
      if (s != null) return s;
    }
    return null;
  }

  /// Returns the [SavedPlanDay] that contains the next incomplete stop.
  SavedPlanDay? get nextIncompleteDay {
    for (final day in days) {
      if (day.nextIncompleteStop != null) return day;
    }
    return null;
  }

  SavedPlan copyWith({
    SoloPlanStatus? status,
    List<SavedPlanDay>? days,
    DateTime? startedAt,
    DateTime? completedAt,
  }) =>
      SavedPlan(
        id: id,
        title: title,
        tagline: tagline,
        type: type,
        curatedTripId: curatedTripId,
        status: status ?? this.status,
        days: days ?? this.days,
        estimatedBudget: estimatedBudget,
        areas: areas,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'tagline': tagline,
        'type': type,
        if (curatedTripId != null) 'curatedTripId': curatedTripId,
        'status': status.name,
        'days': days.map((d) => d.toMap()).toList(),
        'estimatedBudget': estimatedBudget,
        'areas': areas,
        if (startedAt != null)
          'startedAt': Timestamp.fromDate(startedAt!),
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SavedPlan.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return SavedPlan(
      id: doc.id,
      title: m['title'] as String? ?? '',
      tagline: m['tagline'] as String? ?? '',
      type: m['type'] as String? ?? 'custom',
      curatedTripId: m['curatedTripId'] as String?,
      status: SoloPlanStatus.values.firstWhere(
        (s) => s.name == (m['status'] as String? ?? 'saved'),
        orElse: () => SoloPlanStatus.saved,
      ),
      days: (m['days'] as List<dynamic>? ?? [])
          .map((d) => SavedPlanDay.fromMap(Map<String, dynamic>.from(d as Map)))
          .toList(),
      estimatedBudget: m['estimatedBudget'] as String? ?? '',
      areas: List<String>.from(m['areas'] as List<dynamic>? ?? []),
      startedAt: (m['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (m['completedAt'] as Timestamp?)?.toDate(),
      createdAt:
          (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
