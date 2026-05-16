import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GuideLocationService {
  GuideLocationService._();
  static final instance = GuideLocationService._();

  StreamSubscription<Position>? _positionSub;
  bool _isSharing = false;

  bool get isSharing => _isSharing;

  DatabaseReference _ref(String guideId) =>
      FirebaseDatabase.instance.ref('guide_locations/$guideId');

  /// Start broadcasting the guide's location every 15 seconds.
  Future<void> startSharing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _isSharing) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    _isSharing = true;
    final ref = _ref(uid);

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((pos) {
      ref.set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updatedAt': ServerValue.timestamp,
      });
    });

    // Remove stale location when the guide disconnects
    ref.onDisconnect().remove();
  }

  /// Stop broadcasting and clean up.
  Future<void> stopSharing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _positionSub?.cancel();
    _positionSub = null;
    _isSharing = false;
    if (uid != null) await _ref(uid).remove();
  }

  /// Stream the live location of a specific guide (for tourist map view).
  Stream<Map<String, double>?> watchGuide(String guideId) {
    return _ref(guideId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    });
  }

  /// Returns the last known location of a guide (single read, no stream).
  Future<Map<String, double>?> getGuideLocation(String guideId) async {
    try {
      final snap = await _ref(guideId).get();
      if (!snap.exists) return null;
      final data = snap.value as Map<dynamic, dynamic>;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    } catch (e) {
      debugPrint('GuideLocationService.getGuideLocation error: $e');
      return null;
    }
  }
}
