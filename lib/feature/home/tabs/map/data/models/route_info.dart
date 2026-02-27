import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final String distance;
  final String duration;
  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> polylinePoints;
  final LatLngBounds bounds;
  final List<RouteStep> steps;
  final String travelMode;

  const RouteInfo({
    required this.distance,
    required this.duration,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylinePoints,
    required this.bounds,
    required this.steps,
    required this.travelMode,
  });
}

class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });
}