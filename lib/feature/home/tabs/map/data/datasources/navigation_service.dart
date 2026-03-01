import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/route_info.dart';

class NavigationService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Fetches directions from [origin] to [destination].
  ///
  /// [mode] can be: 'driving', 'walking', 'transit', 'bicycling'
  Future<RouteInfo?> getDirections({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
    String mode = 'driving',
  }) async {
    final url = Uri.parse(
      '$_baseUrl'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=$mode'
      '&key=$apiKey',
    );

    debugPrint('🧭 Fetching directions: $mode');
    debugPrint('   From: ${origin.latitude}, ${origin.longitude}');
    debugPrint('   To:   ${destination.latitude}, ${destination.longitude}');

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint('❌ Directions API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        debugPrint('❌ Directions API status: ${data['status']}');
        debugPrint('   ${data['error_message'] ?? ''}');
        return null;
      }

      final route = data['routes'][0];
      final leg = route['legs'][0];

      // Decode overview polyline
      final polylinePoints =
          _decodePolyline(route['overview_polyline']['points']);

      // Parse bounds
      final northeast = route['bounds']['northeast'];
      final southwest = route['bounds']['southwest'];
      final bounds = LatLngBounds(
        northeast: LatLng(northeast['lat'], northeast['lng']),
        southwest: LatLng(southwest['lat'], southwest['lng']),
      );

      // Parse steps
      final steps = <RouteStep>[];
      for (final step in leg['steps']) {
        steps.add(RouteStep(
          instruction: _stripHtmlTags(step['html_instructions'] ?? ''),
          distance: step['distance']['text'] ?? '',
          duration: step['duration']['text'] ?? '',
          startLocation: LatLng(
            step['start_location']['lat'],
            step['start_location']['lng'],
          ),
          endLocation: LatLng(
            step['end_location']['lat'],
            step['end_location']['lng'],
          ),
        ));
      }

      final routeInfo = RouteInfo(
        distance: leg['distance']['text'] ?? '',
        duration: leg['duration']['text'] ?? '',
        distanceMeters: leg['distance']['value'] ?? 0,
        durationSeconds: leg['duration']['value'] ?? 0,
        polylinePoints: polylinePoints,
        bounds: bounds,
        steps: steps,
        travelMode: mode,
      );

      debugPrint('✅ Route found: ${routeInfo.distance}, ${routeInfo.duration}');
      debugPrint('   ${polylinePoints.length} polyline points');
      debugPrint('   ${steps.length} steps');

      return routeInfo;
    } catch (e) {
      debugPrint('❌ Directions error: $e');
      return null;
    }
  }

  /// Standard Google encoded polyline decoder
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  /// Strips HTML tags from direction instructions
  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}