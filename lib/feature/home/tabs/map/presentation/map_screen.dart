import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/active_tour_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/marker_filter_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_marker_service.dart';
import './place_detail_screen.dart';
import './saved_places_screen.dart';
import './near_me_sheet.dart';
import './trip_planner_sheet.dart';
import './map_config.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/map_filter_sheet.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/navigation_info_bar.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/route_steps_sheet.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/map_search_bar.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/map_search_results.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/widgets/sandstorm_overlay.dart';
import 'package:lost_in_egypt/core/models/weather_context.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/core/utils/dataset_resolver.dart';
import 'package:lost_in_egypt/core/widgets/weather_forecast_sheet.dart';

import 'package:lost_in_egypt/feature/home/tabs/map/bloc/map_bloc.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/bloc/map_event.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/bloc/map_state.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lazy gate around the real map UI. PageView eagerly builds intermediate
/// pages during `animateToPage` traversal — without this gate, a Home→More
/// tab transition would instantiate MapBloc and fire the 54-query Places API
/// cold-start batch even though the user never asked for the map. The gate
/// renders a transparent placeholder until the Map tab is actually selected
/// (activeTabNotifier == 2), then swaps in the real BlocProvider + view.
/// Once activated it stays activated for the rest of the app session.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _activated = false;

  @override
  void initState() {
    super.initState();
    final notifier = MapFocusService.instance.activeTabNotifier;
    if (notifier.value == 2) {
      _activated = true;
    } else {
      notifier.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (MapFocusService.instance.activeTabNotifier.value == 2 && !_activated) {
      MapFocusService.instance.activeTabNotifier.removeListener(_onTabChanged);
      if (mounted) setState(() => _activated = true);
    }
  }

  @override
  void dispose() {
    MapFocusService.instance.activeTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_activated) {
      return const ColoredBox(color: Colors.transparent);
    }
    return BlocProvider(
      create: (context) => sl<MapBloc>()..add(MapInitialized()),
      child: const MapScreenView(),
    );
  }
}

class MapScreenView extends StatefulWidget {
  const MapScreenView({super.key});

  @override
  State<MapScreenView> createState() => _MapScreenViewState();
}

class _MapScreenViewState extends State<MapScreenView>
    with AutomaticKeepAliveClientMixin {
  static String get _directionsApiKey =>
      dotenv.env['MAPS_API_KEY'] ?? '';

  final MapMarkerService _markerService = MapMarkerService();
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _routeBoundsApplied = false;
  bool _isFollowingUser = true;
  bool _isProgrammaticMove = false;
  final FlutterTts _flutterTts = FlutterTts();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ── Nearby-place nudge (Phase 7H.2) ───────────────────────────────────────
  // Separate position stream that runs ONLY while the map tab is active — NOT
  // the live-navigation stream (_positionStream). Surfaces a non-intrusive
  // floating card when the user passes near a high-scoring place they haven't
  // been nudged about before. Also works during live navigation.
  //
  // Tuning constants — empirically picked, change with care.
  static const double _kNudgeScoreThreshold = 0.65; // engine returns [-1, 1]; > 0.65 = strong taste match
  static const double _kNudgeMaxDistanceM = 800;    // hard cap so the card never fires for places out of practical walking range
  static const double _kNudgePrefilterRadiusM = 2000; // pre-filter window before sending to engine
  static const int _kNudgeCandidatePoolSize = 30;   // top-N closest to send to engine
  static const Duration _kNudgeThrottle = Duration(seconds: 60);
  static const Duration _kNudgeAutoDismiss = Duration(seconds: 8);
  static const int _kNudgedHistoryCap = 200; // FIFO eviction for the per-session "already-nudged" set

  StreamSubscription<Position>? _nudgeStream;
  _NearbyNudgeData? _activeNudge;
  Timer? _nudgeDismissTimer;
  // LinkedHashSet keeps insertion order so we can evict the oldest entry first.
  final Set<String> _nudgedPlaceIds = <String>{};
  DateTime? _lastNudgeShown;
  bool _evaluatingNudge = false;
  
  double _sheetExtent = 0.55;

  String? _lightMapStyle;
  String? _darkMapStyle;
  Brightness? _lastBrightness;

  StreamSubscription<Position>? _positionStream;
  Set<String> _savedPlaceIds = {};
  Set<String> _visitedLandmarkIds = {};

  // Multi-stop trip state
  List<MapItem> _tripItinerary = [];
  int _tripCurrentIndex = -1;
  bool get _isTripActive => _tripItinerary.isNotEmpty && _tripCurrentIndex >= 0;

  // Expandable FAB menu state
  bool _isFabExpanded = false;

  // Active solo-tour stop — gold pin on map + "Back to Tour" button
  MapItem? _tourStop;

  // View-only route: all stop markers shown, camera fitted to bounds
  List<MapItem> _viewRouteStops = [];

  // Cached popular nearby (shuffled once, not on every rebuild)
  List<MapItem> _cachedPopularPlaces = [];
  int _cachedPopularSourceHash = 0;

  // Weather — sandstorm overlay shown once per sandstorm event
  bool _sandstormShown = false;

  // Map type — normal / satellite toggle
  MapType _mapType = MapType.normal;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WeatherController.weather.addListener(_onWeatherChanged);
    _initializeMapServices();
    _fetchSavedPlaceIds();
    _fetchVisitedLandmarks();

    _searchController.addListener(() {
      context.read<MapBloc>().add(MapSearchQueryChanged(_searchController.text));
    });

    _searchFocusNode.addListener(() {
      if (mounted) {
        context.read<MapBloc>().add(MapSearchFocusChanged(_searchFocusNode.hasFocus));
      }
    });
  }

  Future<void> _initializeMapServices() async {
    await _markerService.loadCustomMarkerIcons();
    await _checkLocationPermission();
    // Refresh weather with actual GPS once permission is confirmed
    Future.microtask(() async {
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 6),
          );
          WeatherController.refresh(pos.latitude, pos.longitude);
        }
      } catch (_) {}
    });

    MapFocusService.instance.focusedItemNotifier.addListener(_onFocusRequested);
    MapFocusService.instance.pendingTripNotifier.addListener(_onPendingTrip);
    MapFocusService.instance.cameraOnlyNotifier.addListener(_onCameraFocusRequested);
    MapFocusService.instance.tourStopNotifier.addListener(_onTourStopRequested);
    MapFocusService.instance.viewRouteNotifier.addListener(_onViewRouteRequested);

    // Nudge monitor — gated on the active-tab notifier so GPS only burns
    // power while the map is actually visible. MapScreen's lazy gate guarantees
    // we're here BECAUSE the map tab activated, so kick off immediately too.
    MapFocusService.instance.activeTabNotifier.addListener(_onMapTabActiveChanged);
    if (MapFocusService.instance.activeTabNotifier.value == 2) {
      _startNudgeMonitor();
    }

    // Rebuild markers now that custom icons are loaded
    if (mounted) {
      final state = context.read<MapBloc>().state;
      _updateVisibleMarkers(state, forceInclude: state.selectedPlace);
    }

    // Check if there's an item already focused before we even loaded
    if (MapFocusService.instance.tourStopNotifier.value != null) {
      _onTourStopRequested();
    } else if (MapFocusService.instance.focusedItemNotifier.value != null) {
      _onFocusRequested();
    } else if (MapFocusService.instance.cameraOnlyNotifier.value != null) {
      _onCameraFocusRequested();
    } else if (MapFocusService.instance.pendingTripNotifier.value != null) {
      _onPendingTrip();
    } else {
      // Zoom to user's location only if no place is focused
      await _zoomToUserLocation();
    }
  }

  Future<void> _fetchSavedPlaceIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _savedPlaceIds = Set<String>.from(doc.data()?['savedPlaces'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching saved places: $e');
    }
  }

  Future<void> _fetchVisitedLandmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _visitedLandmarkIds = Set<String>.from(doc.data()?['visitedLandmarks'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching visited landmarks: $e');
    }
  }

  Future<void> _zoomToUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Could not zoom to user location: $e');
    }
  }

  void _onWeatherChanged() {
    final weather = WeatherController.weather.value;
    if (weather == null) return;
    if (weather.isSandstorm && !_sandstormShown) {
      _sandstormShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) SandstormOverlay.show(context);
      });
    } else if (!weather.isSandstorm) {
      _sandstormShown = false;
    }
  }

  /// Background position stream that fires every ~200 m and asks the
  /// recommendation engine if any nearby place is a strong taste match worth
  /// surfacing as a floating nudge card. Independent of the live-navigation
  /// stream (`_positionStream`) so it can run with or without active routing.
  /// Auto-pauses when the user leaves the map tab (see [_onMapTabActiveChanged]).
  void _startNudgeMonitor() {
    if (_nudgeStream != null) return; // already running
    _nudgeStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 200,
      ),
    ).listen(
      (pos) => _evaluateNudge(pos),
      onError: (e) => debugPrint('Nudge stream error: $e'),
    );
  }

  void _stopNudgeMonitor() {
    _nudgeStream?.cancel();
    _nudgeStream = null;
  }

  /// Pause the GPS stream when the user is on another tab — the nudge UI
  /// is invisible there anyway, so running GPS just drains battery and burns
  /// recommendation-engine quota.
  void _onMapTabActiveChanged() {
    final onMapTab = MapFocusService.instance.activeTabNotifier.value == 2;
    if (onMapTab) {
      _startNudgeMonitor();
    } else {
      _stopNudgeMonitor();
    }
  }

  Future<void> _evaluateNudge(Position pos) async {
    if (!mounted || _evaluatingNudge) return;
    try {
      _evaluatingNudge = true;
      final allItems = context.read<MapBloc>().state.allItemsCache;
      if (allItems.isEmpty) return;

      // Skip if the user is already looking at any place in the detail sheet —
      // a nudge for "the place you're currently reading about" is noise.
      final currentlyOpen = context.read<MapBloc>().state.selectedPlace?.id;

      // Pre-filter to items within prefilter radius. Compute distance once
      // per item and reuse it for both the filter and the subsequent sort.
      final distances = <String, double>{};
      final nearby = <MapItem>[];
      for (final item in allItems) {
        if (_nudgedPlaceIds.contains(item.id)) continue;
        if (item.id == currentlyOpen) continue;
        final d = Geolocator.distanceBetween(
          pos.latitude, pos.longitude,
          item.coordinate.latitude, item.coordinate.longitude,
        );
        if (d <= _kNudgePrefilterRadiusM) {
          distances[item.id] = d;
          nearby.add(item);
        }
      }
      if (nearby.isEmpty) return;

      // Sort by memoised distance — no Haversine inside the comparator.
      nearby.sort((a, b) => distances[a.id]!.compareTo(distances[b.id]!));
      final pool = nearby.take(_kNudgeCandidatePoolSize).toList();

      final candidates = pool.map((i) {
        final urc = i is PlaceModel ? i.userRatingCount : 0;
        return <String, dynamic>{
          'placeId': i.id,
          'name': i.title,
          'types': [i.category],
          'tags': i.tags,
          'rating': i.rating,
          'userRatingCount': urc,
          'lat': i.coordinate.latitude,
          'lng': i.coordinate.longitude,
        };
      }).toList();

      final result = await RecommendationService.recommendPlaces(
        candidates: candidates,
        context: 'nearby',
        limit: 1,
        userLat: pos.latitude,
        userLng: pos.longitude,
        weather: WeatherController.weather.value,
      );
      if (!mounted || result == null || result.recommendations.isEmpty) return;

      final top = result.recommendations.first;
      if (top.score <= _kNudgeScoreThreshold) return;

      final item = pool.firstWhere((i) => i.id == top.placeId,
          orElse: () => pool.first);
      final distanceM = distances[item.id]
          ?? Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            item.coordinate.latitude, item.coordinate.longitude,
          );
      if (distanceM > _kNudgeMaxDistanceM) return;
      if (_nudgedPlaceIds.contains(item.id)) return;

      // Throttle ticks only AFTER a real nudge displays — a stretch of failed
      // evaluations shouldn't gate a subsequent good one.
      final now = DateTime.now();
      if (_lastNudgeShown != null &&
          now.difference(_lastNudgeShown!) < _kNudgeThrottle) {
        return;
      }
      _lastNudgeShown = now;

      // Cap history to prevent unbounded growth across long sessions.
      _nudgedPlaceIds.add(item.id);
      while (_nudgedPlaceIds.length > _kNudgedHistoryCap) {
        _nudgedPlaceIds.remove(_nudgedPlaceIds.first);
      }
      _nudgeDismissTimer?.cancel();
      _nudgeDismissTimer = Timer(_kNudgeAutoDismiss, () {
        if (mounted) setState(() => _activeNudge = null);
      });
      setState(() {
        _activeNudge = _NearbyNudgeData(
          item: item,
          distanceM: distanceM,
          reason: top.reasons.isNotEmpty ? top.reasons.first : null,
        );
      });
    } catch (e, st) {
      debugPrint('Nudge evaluation failed: $e\n$st');
    } finally {
      _evaluatingNudge = false;
    }
  }

  void _dismissNudge() {
    _nudgeDismissTimer?.cancel();
    if (mounted) setState(() => _activeNudge = null);
  }

  @override
  void dispose() {
    WeatherController.weather.removeListener(_onWeatherChanged);
    MapFocusService.instance.activeTabNotifier.removeListener(_onMapTabActiveChanged);
    _positionStream?.cancel();
    _stopNudgeMonitor();
    _nudgeDismissTimer?.cancel();
    MapFocusService.instance.focusedItemNotifier.removeListener(_onFocusRequested);
    MapFocusService.instance.pendingTripNotifier.removeListener(_onPendingTrip);
    MapFocusService.instance.cameraOnlyNotifier.removeListener(_onCameraFocusRequested);
    MapFocusService.instance.tourStopNotifier.removeListener(_onTourStopRequested);
    MapFocusService.instance.viewRouteNotifier.removeListener(_onViewRouteRequested);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _loadAndApplyMapStyleIfNeeded();
    }
  }

  LatLng _offsetTargetForSheet(double lat, double lng, double zoom) {
    const double sheetFraction = 0.55;
    final double degreesVisible = 170.0 / pow(2, zoom);
    final double latOffset = degreesVisible * sheetFraction * 0.5;
    return LatLng(lat - latOffset, lng);
  }

  void _onFocusRequested() {
    final item = MapFocusService.instance.focusedItemNotifier.value;
    if (item != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_viewRouteStops.isNotEmpty) setState(() => _viewRouteStops = []);
        final allItems = context.read<MapBloc>().state.allItemsCache;
        final resolved = DatasetResolver.resolveItem(item, allItems) ?? item;
        context.read<MapBloc>().add(MapPlaceSelected(resolved));
        _focusOnPlace(resolved);
      });
    }
  }

  /// Camera-only focus: pans to coordinates without selecting a place or
  /// opening the detail sheet. Used by curated trip stops.
  void _onCameraFocusRequested() {
    final item = MapFocusService.instance.cameraOnlyNotifier.value;
    if (item != null && mounted) {
      MapFocusService.instance.clearCameraFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusOnPlace(item);
      });
    }
  }

  void _onTourStopRequested() {
    final item = MapFocusService.instance.tourStopNotifier.value;
    if (item != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Resolve against the bundled dataset so the detail sheet shows real
        // photos, reviews, and description instead of a blank synthetic pin.
        final allItems = context.read<MapBloc>().state.allItemsCache;
        final resolved = DatasetResolver.resolveItem(item, allItems) ?? item;
        setState(() { _tourStop = resolved; _viewRouteStops = []; });
        context.read<MapBloc>().add(MapPlaceSelected(resolved));
        _updateVisibleMarkers(context.read<MapBloc>().state, forceInclude: resolved);
        _focusOnPlace(resolved);
      });
    }
  }

  // Synthetic→dataset pin resolution is now in lib/core/utils/dataset_resolver.dart
  // so active_tour_screen and other surfaces can reuse the same matcher.

  void _onPendingTrip() {
    final stops = MapFocusService.instance.pendingTripNotifier.value;
    if (stops != null && stops.isNotEmpty && mounted) {
      MapFocusService.instance.clearPendingTrip();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final allItems = context.read<MapBloc>().state.allItemsCache;
        final resolved =
            stops.map((s) => DatasetResolver.resolveItem(s, allItems) ?? s).toList();
        setState(() {
          _tripItinerary = resolved;
          _tripCurrentIndex = 0;
          _viewRouteStops = [];
        });
        final firstStop = resolved.first;
        context.read<MapBloc>().add(MapPlaceSelected(firstStop));
        _focusOnPlace(firstStop);
        context.read<MapBloc>().add(
          MapDirectionsRequested(
            destination: firstStop,
            apiKey: _directionsApiKey,
            mode: context.read<MapBloc>().state.selectedTravelMode,
          ),
        );
      });
    }
  }

  void _onViewRouteRequested() {
    final rawStops = MapFocusService.instance.viewRouteNotifier.value;
    if (rawStops == null || rawStops.isEmpty || !mounted) return;
    MapFocusService.instance.clearViewRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Resolve synthetic stops → real dataset items so tapping a gold route
      // pin opens the full detail sheet (photos / reviews / description).
      final allItems = context.read<MapBloc>().state.allItemsCache;
      final resolved = rawStops
          .map((s) => DatasetResolver.resolveItem(s, allItems) ?? s)
          .toList();
      setState(() => _viewRouteStops = resolved);
      _updateVisibleMarkers(context.read<MapBloc>().state);
      await _fitBoundsToStops(resolved);
    });
  }

  Future<void> _fitBoundsToStops(List<MapItem> stops) async {
    if (_mapController == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mapController == null) return;
    }
    double minLat = stops.first.coordinate.latitude;
    double maxLat = minLat;
    double minLng = stops.first.coordinate.longitude;
    double maxLng = minLng;
    for (final s in stops) {
      if (s.coordinate.latitude < minLat) minLat = s.coordinate.latitude;
      if (s.coordinate.latitude > maxLat) maxLat = s.coordinate.latitude;
      if (s.coordinate.longitude < minLng) minLng = s.coordinate.longitude;
      if (s.coordinate.longitude > maxLng) maxLng = s.coordinate.longitude;
    }
    // Add a small padding so pins aren't clipped by the screen edge
    const pad = 0.01;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - pad, minLng - pad),
            northeast: LatLng(maxLat + pad, maxLng + pad),
          ),
          80, // pixels of padding inside the viewport
        ),
      );
    } catch (e) {
      debugPrint('_fitBoundsToStops error: $e');
    }
  }

  Future<void> _focusOnPlace(MapItem place) async {
    if (_mapController == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mapController == null) return;
    }

    const double targetZoom = 17;
    final offsetTarget = _offsetTargetForSheet(
      place.coordinate.latitude,
      place.coordinate.longitude,
      targetZoom,
    );

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: offsetTarget, zoom: targetZoom),
        ),
      );
      if (!mounted) return;
      context.read<MapBloc>().add(const MapZoomChanged(targetZoom));
    } catch (e) {
      debugPrint('Camera animation error: $e');
    }
    
    MapFocusService.instance.clearFocus();
  }

  void _updateVisibleMarkers(MapState state, {MapItem? forceInclude}) {
    if (state.allItems.isEmpty && forceInclude == null) {
      if (mounted) setState(() => _markers = {});
      return;
    }

    // In navigation mode, only show the destination pin
    if (state.isNavigationMode && state.navigationDestination != null) {
      final dest = state.navigationDestination!;
      final destMarker = Marker(
        markerId: MarkerId(dest.id),
        position: LatLng(dest.coordinate.latitude, dest.coordinate.longitude),
        icon: _markerService.getMarkerIconByCategory(dest, true),
        anchor: const Offset(0.5, 1.0),
      );
      if (mounted) setState(() => _markers = {destMarker});
      return;
    }

    List<MapItem> filteredItems;
    if (state.selectedUiCategoryId == 'favorites') {
      filteredItems = state.allItems.where((item) => _savedPlaceIds.contains(item.id)).toList();
    } else if (state.selectedUiCategoryId == 'open_now') {
      filteredItems = state.allItems.where((item) => item.isCurrentlyOpen).toList();
    } else if (state.selectedUiCategoryId != 'all') {
      filteredItems = state.allItems;
    } else {
      filteredItems = MarkerFilterService.filterByZoom(state.allItems, state.currentZoom);
    }

    if (forceInclude != null && !filteredItems.any((p) => p.id == forceInclude.id)) {
      filteredItems = [...filteredItems, forceInclude];
    }

    final markers = filteredItems.map((item) {
      final isSelected = state.selectedPlace?.id == item.id;
      final isVisited = _visitedLandmarkIds.contains(item.id) ||
          _visitedLandmarkIds.contains(item.title);
      // When this marker IS the active tour stop, paint it gold (instead
      // of stacking a separate gold pin on top of the regular one — that
      // hid the dataset pin and broke the photos/reviews flow).
      final isTourStop = _tourStop?.id == item.id;
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        icon: isTourStop
            ? BitmapDescriptor.defaultMarkerWithHue(50.0)
            : _markerService.getMarkerIconByCategory(item, isSelected),
        anchor: const Offset(0.5, 1.0),
        alpha: isVisited ? 0.7 : 1.0,
        zIndexInt: isTourStop ? 10 : 0,
        onTap: () {
          debugPrint('📍 Marker tapped: ${item.title} (id: ${item.id})');
          _searchController.clear();
          _searchFocusNode.unfocus();
          context.read<MapBloc>().add(MapPlaceSelected(item));
          _focusOnPlace(item);
        },
      );
    }).toSet();

    // View-route pins — gold numbered markers for each stop in the route overview
    final viewRouteMarkers = _viewRouteStops.asMap().entries.map((entry) {
      final stop = entry.value;
      return Marker(
        markerId: MarkerId('__route_stop_${entry.key}__'),
        position: LatLng(stop.coordinate.latitude, stop.coordinate.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(50.0),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: 9,
        onTap: () {
          context.read<MapBloc>().add(MapPlaceSelected(stop));
          _focusOnPlace(stop);
        },
      );
    }).toSet();

    if (mounted) {
      setState(() => _markers = {...markers, ...viewRouteMarkers});
    }
  }

  void _updatePolylines(MapState state) {
    if (state.currentRoute == null) {
      if (mounted) setState(() => _polylines = {});
      _routeBoundsApplied = false;
      return;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color routeColor;
    switch (state.selectedTravelMode) {
      case 'walking':
        routeColor = isDarkMode ? const Color(0xFF4DB6AC) : const Color(0xFF00897B); // Teal
        break;
      case 'transit':
        routeColor = isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00); // Amber/Orange
        break;
      default:
        routeColor = isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2); // Blue
    }

    final polyline = Polyline(
      polylineId: const PolylineId('navigation_route'),
      points: state.currentRoute!.polylinePoints,
      color: routeColor,
      width: 5,
      patterns: state.selectedTravelMode == 'walking'
          ? [PatternItem.dot, PatternItem.gap(10)]
          : [],
    );

    if (mounted) setState(() => _polylines = {polyline});
    
    // Only zoom to fit route bounds ONCE when route first appears
    if (!_routeBoundsApplied) {
      _routeBoundsApplied = true;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(state.currentRoute!.bounds, 80),
      );
    }
  }

  Future<void> _loadAndApplyMapStyleIfNeeded() async {
    _lightMapStyle ??= await rootBundle.loadString('assets/map_style.json');
    if (_darkMapStyle == null) {
      try {
        _darkMapStyle = await rootBundle.loadString('assets/darkmode_map_style.json');
      } catch (_) {
        _darkMapStyle = _lightMapStyle;
      }
    }
    await _applyCurrentMapStyle();
  }

  Future<void> _applyCurrentMapStyle() async {
    if (mounted) setState(() {});
  }

  Future<void> _checkLocationPermission() async {
    final granted = await Geolocator.checkPermission() == LocationPermission.whileInUse || 
                    await Geolocator.checkPermission() == LocationPermission.always;
    if (!granted) {
      final requested = await Geolocator.requestPermission();
      if (!mounted) return;
      context.read<MapBloc>().add(MapLocationPermissionUpdated(
        requested == LocationPermission.whileInUse || requested == LocationPermission.always
      ));
    } else {
      if (!mounted) return;
      context.read<MapBloc>().add(const MapLocationPermissionUpdated(true));
    }
  }

  Future<void> _goToUserLocation(bool isGranted) async {
    if (!isGranted) {
      await _checkLocationPermission();
      return;
    }
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15),
      ),
    );
  }

  void _startLiveNavigation() async {
    final state = context.read<MapBloc>().state;
    final dest = state.navigationDestination;
    
    // Easter Egg: Mummy's Curse
    if (dest != null && (dest.title.toLowerCase().contains('valley of the kings') || dest.title.toLowerCase().contains('tomb'))) {
      await _flutterTts.setPitch(0.4);
      await _flutterTts.setSpeechRate(0.3);
      await _flutterTts.speak("You dare awaken the Pharaoh... The curse is upon you.");
    }
    
    // Easter Egg: Sandstorm Mode
    if (dest != null && dest.title.toLowerCase().contains('sahara desert')) {
      if (!mounted) return;
      SandstormOverlay.show(context);
      await _flutterTts.setPitch(0.6);
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.speak("The desert consumes all.");
    }

    if (!mounted) return;
    context.read<MapBloc>().add(const MapLiveNavigationStarted());
    _isFollowingUser = true;
    
    // Get actual user position for initial camera
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 17,
            tilt: 45,
          ),
        ),
      );
    } catch (_) {}

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      
      context.read<MapBloc>().add(
        MapUserLocationUpdated(position.latitude, position.longitude),
      );
      
      // Only move camera if user hasn't manually panned away
      if (_isFollowingUser) {
        _isProgrammaticMove = true;
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    });
  }

  void _stopLiveNavigation() async {
    _positionStream?.cancel();
    _positionStream = null;
    _isFollowingUser = true;
    context.read<MapBloc>().add(const MapLiveNavigationStopped());
    // Reset camera tilt using current position
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 14,
            tilt: 0,
          ),
        ),
      );
    } catch (_) {
      // Just reset tilt without moving
      _mapController?.animateCamera(
        CameraUpdate.zoomTo(14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);

    Color chipBg({bool strong = false}) => surface.withValues(alpha: strong ? (isDark ? 0.92 : 0.95) : 0.92);

    return BlocConsumer<MapBloc, MapState>(
      listenWhen: (previous, current) {
        return previous.selectedPlace != current.selectedPlace ||
               previous.allItems != current.allItems ||
               previous.selectedUiCategoryId != current.selectedUiCategoryId ||
               previous.currentZoom != current.currentZoom ||
               previous.currentRoute != current.currentRoute ||
               previous.isLiveNavigating != current.isLiveNavigating ||
               previous.hasArrived != current.hasArrived ||
               previous.error != current.error;
      },
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          context.read<MapBloc>().add(const MapErrorCleared());
        }
        
        // Arrival detection — show dialog and stop tracking
        if (state.hasArrived && state.navigationDestination != null) {
          _stopLiveNavigation();
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Row(
                children: [
                  Text('🎉 ', style: TextStyle(fontSize: 28.sp)),
                  const Text('You\'ve Arrived!'),
                ],
              ),
              content: Text(
                'You have arrived at ${state.navigationDestination!.title}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<MapBloc>().add(MapNavigationCleared());
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }

        _updateVisibleMarkers(state, forceInclude: state.selectedPlace);
        _updatePolylines(state);
      },
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: MapConfig.initialPosition,
                markers: _markers,
                polylines: _polylines,
                mapType: _mapType,
                myLocationEnabled: state.isLocationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                style: isDark ? _darkMapStyle : _lightMapStyle,
                onMapCreated: (controller) async {
                  _mapController = controller;
                  await _loadAndApplyMapStyleIfNeeded();
                },
                onCameraMoveStarted: () {
                  // Pause auto-follow only if this was a user gesture, not our programmatic move
                  if (state.isLiveNavigating && _isFollowingUser && !_isProgrammaticMove) {
                    setState(() => _isFollowingUser = false);
                  }
                  _isProgrammaticMove = false;
                },
                onCameraMove: (_) {
                  // Don't dispatch zoom changes during gestures
                },
                onCameraIdle: () async {
                  // Skip zoom updates during live navigation to avoid interference
                  if (state.isLiveNavigating) return;
                  final zoom = await _mapController?.getZoomLevel() ?? state.currentZoom;
                  if (context.mounted) {
                    context.read<MapBloc>().add(MapZoomChanged(zoom));
                  }
                },
                onTap: (_) {
                  // Only unfocus keyboard, don't clear search text so results persist
                  if (state.isSearchActive) {
                    _searchFocusNode.unfocus();
                  }
                  if (state.selectedPlace != null) {
                    context.read<MapBloc>().add(const MapPlaceSelected(null));
                  }
                  if (_isFabExpanded) {
                    setState(() => _isFabExpanded = false);
                  }
                },
              ),

              // ── Loading overlay ──
              if (state.isLoading && state.allItems.isEmpty)
                Positioned.fill(
                  child: Container(
                    color: surface.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48.r, height: 48.r,
                            child: CircularProgressIndicator(strokeWidth: 3, color: primary),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Discovering Egypt...',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: onSurface.withValues(alpha: 0.7),
                              fontFamily: 'Marcellus',
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Loading places near you',
                            style: TextStyle(fontSize: 13.sp, color: onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Popular nearby suggestions ──
              if (state.selectedPlace == null &&
                  !state.isNavigationMode &&
                  !state.isSearchActive &&
                  !_isTripActive &&
                  state.allItems.isNotEmpty)
                Builder(
                  builder: (context) {
                    // Recompute only when source data changes
                    final sourceHash = state.allItemsCache.length;
                    if (_cachedPopularPlaces.isEmpty || _cachedPopularSourceHash != sourceHash) {
                      _cachedPopularSourceHash = sourceHash;
                      _cachedPopularPlaces = state.allItemsCache
                          .where((p) =>
                              p.rating >= 4.0 &&
                              p.importance >= 7 &&
                              p.imagePaths.isNotEmpty &&
                              p.category.toLowerCase() != 'hotel' &&
                              p.category.toLowerCase() != 'food' &&
                              p.category.toLowerCase() != 'shopping')
                          .toList()
                        ..shuffle();
                      _cachedPopularPlaces = _cachedPopularPlaces.take(10).toList();
                    }
                    final displayPlaces = _cachedPopularPlaces;
                    if (displayPlaces.isEmpty) return const SizedBox.shrink();

                    return Positioned(
                      bottom: 105.h,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 20.w, bottom: 8.h),
                            child: Text(
                              '🔥 Top Rated',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: onSurface.withValues(alpha: 0.6),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 110.h,
                            child: ListView.separated(
                              clipBehavior: Clip.none,
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              separatorBuilder: (_, _) => SizedBox(width: 12.w),
                              itemCount: displayPlaces.length,
                              itemBuilder: (context, index) {
                                final item = displayPlaces[index];
                                return GestureDetector(
                                  onTap: () {
                                    context.read<MapBloc>().add(MapPlaceSelected(item));
                                    _focusOnPlace(item);
                                  },
                                  child: Container(
                                    width: 200.w,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Background image
                                        ShimmerImage(
                                          url: item.imagePaths.first,
                                          fit: BoxFit.cover,
                                          fallbackIcon: Icons.place,
                                          fallbackBackgroundColor: onSurface.withValues(alpha: 0.1),
                                          fallbackIconColor: primary,
                                          fallbackIconSize: 28.r,
                                        ),
                                        // Gradient overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.75),
                                              ],
                                              stops: const [0.3, 1.0],
                                            ),
                                          ),
                                        ),
                                        // Category badge
                                        Positioned(
                                          top: 8.h,
                                          left: 8.w,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.45),
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                            child: Text(
                                              item.category.toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 9.sp,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Bottom text
                                        Positioned(
                                          bottom: 10.h,
                                          left: 10.w,
                                          right: 10.w,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.2,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                children: [
                                                  ...List.generate(
                                                    item.rating.round().clamp(0, 5),
                                                    (_) => Icon(Icons.star_rounded, size: 13.r, color: const Color(0xFFFFD700)),
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    item.rating.toStringAsFixed(1),
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 11.sp,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),


              // ── Weather chip ──────────────────────────────────────────────
              if (!state.isSearchActive && !state.isNavigationMode && !_isTripActive)
                Positioned(
                  top: 110.h,
                  right: 76.w,
                  child: ValueListenableBuilder<WeatherContext?>(
                    valueListenable: WeatherController.weather,
                    builder: (_, weather, _) {
                      if (weather == null) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => WeatherForecastSheet.show(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: chipBg(),
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))],
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(weather.conditionIcon, color: weather.severityColor, size: 17.r),
                              SizedBox(width: 5.w),
                              Text(
                                weather.tempDisplay,
                                style: TextStyle(
                                  color: weather.isOutdoorAdvisory
                                      ? weather.severityColor
                                      : onSurface.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (!state.isSearchActive && !state.isNavigationMode && !_isTripActive)
                Positioned(
                  top: 110.h,
                  right: 20.w,
                  child: Material(
                    color: state.selectedUiCategoryId == 'all' ? chipBg() : primary.withValues(alpha: isDark ? 0.90 : 0.95),
                    borderRadius: BorderRadius.circular(30.r),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () async {
                        final chosen = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: surface,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => MapFilterSheet(
                            selectedCategory: state.selectedUiCategoryId,
                            allItems: state.allItemsCache,
                            savedPlaceIds: _savedPlaceIds,
                            onCategorySelected: (category) => Navigator.pop(context, category),
                          ),
                        );
                        if (chosen != null) {
                          if (!context.mounted) return;
                          context.read<MapBloc>().add(MapCategoryChanged(chosen));
                        }
                      },
                      borderRadius: BorderRadius.circular(30.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))],
                          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune,
                              color: state.selectedUiCategoryId == 'all' ? onSurface.withValues(alpha: 0.9) : Colors.white,
                              size: 20.r,
                            ),
                            if (state.selectedUiCategoryId != 'all') ...[
                              SizedBox(width: 6.w),
                              Text(
                                MapConfig.categories.firstWhere((c) => c.id == state.selectedUiCategoryId, orElse: () => const UiCategory('', '', '')).icon,
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Nearby place nudge — surfaces when the user passes a
              // high-scoring taste-matched place. Hidden during search and
              // active trip flows (those are explicit user intents). Stays
              // visible during navigation but slides down to avoid the
              // top-of-screen turn-by-turn instructions panel.
              if (_activeNudge != null &&
                  !state.isSearchActive &&
                  !_isTripActive)
                Positioned(
                  top: state.isLiveNavigating ? 168.h : 110.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _NearbyNudgeCard(
                      data: _activeNudge!,
                      compact: state.isLiveNavigating,
                      onTap: () {
                        final item = _activeNudge!.item;
                        _dismissNudge();
                        MapFocusService.instance.triggerFocus(item);
                      },
                      onDismiss: _dismissNudge,
                    ),
                  ),
                ),

              if (!state.isSearchActive && !state.isNavigationMode && !_isTripActive)
                Positioned(
                  top: 110.h,
                  left: 20.w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FloatingActionButton.small(
                        heroTag: "location_btn",
                        backgroundColor: chipBg(),
                        onPressed: () => _goToUserLocation(state.isLocationPermissionGranted),
                        child: Icon(
                          Icons.my_location,
                          color: state.isLocationPermissionGranted ? primary : onSurface.withValues(alpha: 0.9),
                          size: 20.r,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      FloatingActionButton.small(
                        heroTag: "satellite_btn",
                        backgroundColor: _mapType == MapType.satellite ? primary : chipBg(),
                        onPressed: () => setState(() {
                          _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
                        }),
                        child: Icon(
                          Icons.satellite_alt_rounded,
                          color: _mapType == MapType.satellite ? Colors.white : primary,
                          size: 20.r,
                        ),
                      ),
                      if (!state.isNavigationMode) ...[
                        SizedBox(height: 16.h),
                        // Main toggle FAB for Explore
                        FloatingActionButton(
                          heroTag: 'explore_toggle_btn',
                          backgroundColor: _isFabExpanded ? primary : chipBg(),
                          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
                          child: AnimatedRotation(
                            turns: _isFabExpanded ? 0.125 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.explore,
                              color: _isFabExpanded ? Colors.white : primary,
                            ),
                          ),
                        ),
                        // Expandable options underneath
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _isFabExpanded
                              ? Padding(
                                  padding: EdgeInsets.only(top: 12.h),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildMiniFab(
                                        heroTag: 'trip_planner_btn',
                                        icon: Icons.route_rounded,
                                        label: 'Trip',
                                        primary: primary,
                                        chipBg: chipBg(),
                                        onTap: () async {
                                          setState(() => _isFabExpanded = false);
                                          final itinerary = await showModalBottomSheet<List<MapItem>>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => TripPlannerSheet(allItems: state.allItemsCache),
                                          );
                                          if (itinerary != null && itinerary.isNotEmpty && context.mounted) {
                                            setState(() {
                                              _tripItinerary = itinerary;
                                              _tripCurrentIndex = 0;
                                            });
                                            final firstStop = itinerary.first;
                                            context.read<MapBloc>().add(MapPlaceSelected(firstStop));
                                            _focusOnPlace(firstStop);
                                            context.read<MapBloc>().add(
                                              MapDirectionsRequested(
                                                destination: firstStop,
                                                apiKey: _directionsApiKey,
                                                mode: state.selectedTravelMode,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      SizedBox(height: 12.h),
                                      _buildMiniFab(
                                        heroTag: 'near_me_btn',
                                        icon: Icons.near_me,
                                        label: 'Near Me',
                                        primary: primary,
                                        chipBg: chipBg(),
                                        onTap: () async {
                                          setState(() => _isFabExpanded = false);
                                          final selectedPlace = await showModalBottomSheet<MapItem>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => NearMeSheet(allItems: state.allItemsCache),
                                          );
                                          if (selectedPlace != null && context.mounted) {
                                            context.read<MapBloc>().add(MapPlaceSelected(selectedPlace));
                                            _focusOnPlace(selectedPlace);
                                          }
                                        },
                                      ),
                                      SizedBox(height: 12.h),
                                      _buildMiniFab(
                                        heroTag: 'saved_places_btn',
                                        icon: Icons.bookmarks_rounded,
                                        label: 'Saved',
                                        primary: primary,
                                        chipBg: chipBg(),
                                        onTap: () async {
                                          setState(() => _isFabExpanded = false);
                                          final selectedPlace = await showModalBottomSheet<MapItem>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => SavedPlacesSheet(allItems: state.allItemsCache),
                                          );
                                          if (selectedPlace != null && context.mounted) {
                                            context.read<MapBloc>().add(MapPlaceSelected(selectedPlace));
                                            _focusOnPlace(selectedPlace);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),

              if (state.selectedUiCategoryId != 'all' && !state.isSearchActive && !state.isNavigationMode)
                Positioned(
                  bottom: state.selectedPlace != null ? 350.h : 110.h,
                  left: 20.w,
                  child: FloatingActionButton.extended(
                    heroTag: "reset_filter_btn",
                    backgroundColor: chipBg(),
                    onPressed: () => context.read<MapBloc>().add(const MapCategoryChanged('all')),
                    icon: Icon(Icons.close, color: onSurface.withValues(alpha: 0.9), size: 18.r),
                    label: Text('Reset', style: TextStyle(color: onSurface.withValues(alpha: 0.9))),
                  ),
                ),
              // Trip progress bar
              if (_isTripActive)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12.h,
                  left: 16.w,
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: chipBg(),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32.r, height: 32.r,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${_tripCurrentIndex + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Stop ${_tripCurrentIndex + 1} of ${_tripItinerary.length}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _tripItinerary[_tripCurrentIndex].title,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_tripCurrentIndex < _tripItinerary.length - 1)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _tripCurrentIndex++;
                              });
                              final nextStop = _tripItinerary[_tripCurrentIndex];
                              context.read<MapBloc>().add(MapPlaceSelected(nextStop));
                              _focusOnPlace(nextStop);
                              context.read<MapBloc>().add(
                                MapDirectionsRequested(
                                  destination: nextStop,
                                  apiKey: _directionsApiKey,
                                  mode: state.selectedTravelMode,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'Next Stop',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ),
                        if (_tripCurrentIndex >= _tripItinerary.length - 1)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _tripItinerary = [];
                                _tripCurrentIndex = -1;
                              });
                              context.read<MapBloc>().add(MapNavigationCleared());
                              context.read<MapBloc>().add(const MapPlaceSelected(null));
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'Done! 🎉',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(width: 6.w),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _tripItinerary = [];
                              _tripCurrentIndex = -1;
                            });
                            context.read<MapBloc>().add(MapNavigationCleared());
                            context.read<MapBloc>().add(const MapPlaceSelected(null));
                          },
                          child: Icon(Icons.close, size: 20.r, color: onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Back to Tour button (shown when a solo plan stop is active) ──
              if (_tourStop != null && !state.isNavigationMode)
                Positioned(
                  bottom: state.selectedPlace != null ? 370.h : 105.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        final SavedPlan? plan =
                            MapFocusService.instance.activeTourPlan;
                        MapFocusService.instance.clearTourStop();
                        setState(() => _tourStop = null);
                        _updateVisibleMarkers(context.read<MapBloc>().state,
                            forceInclude: state.selectedPlace);
                        if (plan != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveTourScreen(plan: plan),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6A00F),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tour_outlined,
                                color: Colors.white, size: 18.r),
                            SizedBox(width: 8.w),
                            Text(
                              'Back to Tour',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                                fontFamily: 'Marcellus',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (state.selectedPlace != null && !state.isNavigationMode)
                PlaceDetailSheet(
                  place: state.selectedPlace!,
                  allItems: state.allItemsCache,
                  onClose: () {
                    context.read<MapBloc>().add(const MapPlaceSelected(null));
                    setState(() => _sheetExtent = 0.55); // Reset
                  },
                  onShowOnMap: () => _focusOnPlace(state.selectedPlace!),
                  onDirections: () => context.read<MapBloc>().add(
                    MapDirectionsRequested(
                      destination: state.selectedPlace!,
                      apiKey: _directionsApiKey,
                      mode: state.selectedTravelMode,
                    ),
                  ),
                  onScrollExtentChanged: (extent) {
                    if (mounted) setState(() => _sheetExtent = extent);
                  },
                  onSavedToggled: () => _fetchSavedPlaceIds(),
                ),

              if (state.isNavigationMode && !state.isLiveNavigating)
                Positioned(
                  bottom: 80.h, left: 0, right: 0,
                  child: state.currentRoute != null
                      ? NavigationInfoBar(
                          routeInfo: state.currentRoute!,
                          selectedMode: state.selectedTravelMode,
                          isLoadingRoute: state.isLoadingRoute,
                          onClose: () {
                            _stopLiveNavigation();
                            context.read<MapBloc>().add(MapNavigationCleared());
                          },
                          onStartNavigation: _startLiveNavigation,
                          onShowSteps: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => RouteStepsSheet(routeInfo: state.currentRoute!),
                            );
                          },
                          onModeChanged: (mode) => context.read<MapBloc>().add(
                            MapNavigationModeChanged(mode, _directionsApiKey)
                          ),
                        )
                      : state.isLoadingRoute
                          ? Container(
                              margin: EdgeInsets.all(16.r),
                              padding: EdgeInsets.all(24.r),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [BoxShadow(color: shadowColor, blurRadius: 20, spreadRadius: 2, offset: const Offset(0, -4))],
                                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20.r, height: 20.r, child: CircularProgressIndicator(strokeWidth: 2.5, color: primary)),
                                  SizedBox(width: 14.w),
                                  Text('Finding route...', style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 15.sp, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  Material(
                                    color: onSurface.withValues(alpha: 0.08),
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.hardEdge,
                                    child: InkWell(
                                      onTap: () => context.read<MapBloc>().add(MapNavigationCleared()),
                                      customBorder: const CircleBorder(),
                                      child: SizedBox(
                                        width: 36.r,
                                        height: 36.r,
                                        child: Icon(Icons.close_rounded, color: onSurface.withValues(alpha: 0.6), size: 20.r),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                ),

              // ─── LIVE NAVIGATION INSTRUCTION BAR ───
              if (state.isLiveNavigating && state.currentRoute != null)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Container(
                      margin: EdgeInsets.all(12.r),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 16, spreadRadius: 1)],
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current step instruction
                          if (state.currentStepIndex < state.currentRoute!.steps.length) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(Icons.navigation_rounded, color: primary, size: 22.r),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.currentRoute!.steps[state.currentStepIndex].instruction,
                                        style: TextStyle(
                                          color: onSurface,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                       SizedBox(height: 4.h),
                                      Text(
                                        '${state.currentRoute!.steps[state.currentStepIndex].distance} · ${state.currentRoute!.steps[state.currentStepIndex].duration}',
                                        style: TextStyle(
                                          color: onSurface.withValues(alpha: 0.5),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Overall ETA
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Row(
                                children: [
                                  Icon(Icons.flag_rounded, color: primary, size: 16.r),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '${state.currentRoute!.distance} · ${state.currentRoute!.duration} total',
                                    style: TextStyle(
                                      color: onSurface.withValues(alpha: 0.6),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Step progress bar
                            Row(
                              children: [
                                Text(
                                  'Step ${state.currentStepIndex + 1}/${state.currentRoute!.steps.length}',
                                  style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 12.sp),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (state.currentStepIndex + 1) / state.currentRoute!.steps.length,
                                    backgroundColor: onSurface.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation(primary),
                                    minHeight: 4.h,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Material(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                    onTap: () {
                                      _stopLiveNavigation();
                                      context.read<MapBloc>().add(MapNavigationCleared());
                                    },
                                    customBorder: const CircleBorder(),
                                    child: SizedBox(
                                      width: 30.r,
                                      height: 30.r,
                                      child: Icon(Icons.stop_rounded, color: Colors.red, size: 18.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── RE-CENTER BUTTON (when user pans away during live nav) ───
              if (state.isLiveNavigating && !_isFollowingUser)
                Positioned(
                  bottom: 30.h, right: 16.w,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    backgroundColor: primary,
                    onPressed: () async {
                      setState(() => _isFollowingUser = true);
                      try {
                        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(pos.latitude, pos.longitude),
                              zoom: 17,
                              tilt: 45,
                            ),
                          ),
                        );
                      } catch (_) {}
                    },
                    child: Icon(Icons.my_location_rounded, color: Colors.white, size: 20.r),
                  ),
                ),


              if (state.isSearchActive)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.black.withValues(alpha: 0.25)),
                  ),
                ),

              if (!state.isLiveNavigating && !_isTripActive)
              Positioned(
                top: 50.h, left: 0, right: 0,
                child: IgnorePointer(
                  ignoring: _sheetExtent > 0.6,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _sheetExtent > 0.6 ? 0.0 : 1.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MapSearchBar(
                          searchController: _searchController,
                          searchFocusNode: _searchFocusNode,
                          onClearSearch: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                          }
                        ),
                        SizedBox(height: 8.h),
                        if (state.isSearchActive || _searchController.text.trim().isNotEmpty)
                          MapSearchResults(
                            searchResults: state.searchResults,
                            hasSearchText: _searchController.text.trim().isNotEmpty,
                            onSearchResultTapped: (item) {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              context.read<MapBloc>().add(MapPlaceSelected(item));
                              _focusOnPlace(item);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniFab({
    required String heroTag,
    required IconData icon,
    required String label,
    required Color primary,
    required Color chipBg,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: heroTag,
          backgroundColor: chipBg,
          onPressed: onTap,
          child: Icon(icon, color: primary, size: 20.r),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Nearby place nudge ───────────────────────────────────────────────────────
//
// Tiny floating pill card surfaced when the user walks within 800 m of a
// high-scoring (taste-matched) place. One nudge per place per session.

class _NearbyNudgeData {
  final MapItem item;
  final double distanceM;
  final String? reason;
  const _NearbyNudgeData({
    required this.item,
    required this.distanceM,
    this.reason,
  });
}

class _NearbyNudgeCard extends StatefulWidget {
  final _NearbyNudgeData data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  /// Compact variant — used during live navigation so the card doesn't
  /// dominate the screen while the user is following directions.
  final bool compact;

  const _NearbyNudgeCard({
    required this.data,
    required this.onTap,
    required this.onDismiss,
    this.compact = false,
  });

  @override
  State<_NearbyNudgeCard> createState() => _NearbyNudgeCardState();
}

class _NearbyNudgeCardState extends State<_NearbyNudgeCard>
    with TickerProviderStateMixin {
  /// One-shot entrance: drops in from above with a spring-y overshoot + fades in.
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  /// Continuous pulse on the AI sparkle icon — never stops while the card is alive.
  late final AnimationController _pulseCtrl;

  /// One-shot diagonal shimmer sweep across the card on first display.
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entranceScale = CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut);
    _entranceFade = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0, 0.55, curve: Curves.easeOut));
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  String get _distanceLabel {
    final m = widget.data.distanceM;
    if (m < 100) return '${m.round()} m';
    if (m < 1000) return '${(m / 10).round() * 10} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    // Gold-leaning gradient that pops against both the map and the dark theme.
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF1A2A38), const Color(0xFF243B4F), const Color(0xFF2B1F0D)]
          : [const Color(0xFFFFF7DC), const Color(0xFFFFE8B5), const Color(0xFFFFD27A)],
    );
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final card = SlideTransition(
      position: _entranceSlide,
      child: FadeTransition(
        opacity: _entranceFade,
        child: ScaleTransition(
          scale: _entranceScale,
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              // Glow strength oscillates with the pulse — most visible while idle.
              final glow = 0.35 + (_pulseCtrl.value * 0.35);
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: glow * 0.55),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child!,
              );
            },
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: primary.withValues(alpha: 0.15),
                highlightColor: primary.withValues(alpha: 0.08),
                child: Stack(
                  children: [
                    // Gradient fill underneath everything.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ),
                    // One-shot diagonal shimmer sweep on appear.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _ShimmerSweepPainter(
                                progress: _shimmerCtrl.value,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Inner content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (widget.compact ? 12 : 14).w,
                        vertical: (widget.compact ? 10 : 12).h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _PulsingSparkle(controller: _pulseCtrl, primary: primary),
                          SizedBox(width: 12.w),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: (widget.compact ? 200 : 230).w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Small-caps AI label
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: isDark ? 0.30 : 0.18),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        'AI PICK',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFFFD27A) : primary,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Icon(Icons.directions_walk_rounded,
                                        size: 12.r, color: textColor.withValues(alpha: 0.6)),
                                    SizedBox(width: 2.w),
                                    Text(
                                      _distanceLabel,
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.7),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: (widget.compact ? 2 : 4).h),
                                Text(
                                  widget.data.item.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: (widget.compact ? 14 : 15).sp,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Marcellus',
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!widget.compact && widget.data.reason != null) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    widget.data.reason!,
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.7),
                                      fontSize: 11.sp,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Tap-affordance arrow
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18.r,
                            color: textColor.withValues(alpha: 0.55),
                          ),
                          // Dismiss
                          InkResponse(
                            onTap: widget.onDismiss,
                            radius: 18.r,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4.w),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16.r,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Subtle outer halo — the pulsing primary glow already covers most of it,
    // but a tiny `onSurface`-tinted ring keeps the card readable against pale
    // tiles in light mode.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: onSurface.withValues(alpha: 0.04)),
        ),
        child: card,
      ),
    );
  }
}

/// Sparkle icon that breathes between two scales + tints — the recognisable
/// "AI is thinking" signal across the app.
class _PulsingSparkle extends StatelessWidget {
  final AnimationController controller;
  final Color primary;
  const _PulsingSparkle({required this.controller, required this.primary});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final scale = 0.92 + (t * 0.16);
        final ringAlpha = 0.22 + (t * 0.28);
        return SizedBox(
          width: 36.r,
          height: 36.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Container(
                width: 36.r - (t * 4),
                height: 36.r - (t * 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: ringAlpha),
                    width: 1.5,
                  ),
                ),
              ),
              // Inner filled circle
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 26.r,
                  height: 26.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        primary.withValues(alpha: 0.65),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.45 + t * 0.35),
                        blurRadius: 10 + t * 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14.r,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Diagonal white-band sweep painted across the card body on first appear.
/// `progress` 0..1 moves the band from off-left to off-right.
class _ShimmerSweepPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ShimmerSweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final bandWidth = size.width * 0.35;
    final travel = size.width + bandWidth;
    final centerX = -bandWidth / 2 + (travel * progress);

    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0),
        color,
        color.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(centerX - bandWidth / 2, 0, bandWidth, size.height));

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
