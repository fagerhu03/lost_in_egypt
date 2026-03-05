import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:lost_in_egypt/core/di/service_locator.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/marker_filter_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_marker_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/models/route_info.dart';
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

import 'package:lost_in_egypt/feature/home/tabs/map/bloc/map_bloc.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/bloc/map_event.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/bloc/map_state.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

class _MapScreenViewState extends State<MapScreenView> {
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

  @override
  void initState() {
    super.initState();
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

    MapFocusService.instance.focusedItemNotifier.addListener(_onFocusRequested);

    // Rebuild markers now that custom icons are loaded
    if (mounted) {
      final state = context.read<MapBloc>().state;
      _updateVisibleMarkers(state, forceInclude: state.selectedPlace);
    }

    // Check if there's an item already focused before we even loaded
    if (MapFocusService.instance.focusedItemNotifier.value != null) {
      _onFocusRequested();
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

  @override
  void dispose() {
    _positionStream?.cancel();
    MapFocusService.instance.focusedItemNotifier.removeListener(_onFocusRequested);
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
        context.read<MapBloc>().add(MapPlaceSelected(item));
        _focusOnPlace(item);
      });
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
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        icon: _markerService.getMarkerIconByCategory(item, isSelected),
        anchor: const Offset(0.5, 1.0),
        alpha: isVisited ? 0.7 : 1.0,
        onTap: () {
          debugPrint('📍 Marker tapped: ${item.title} (id: ${item.id})');
          _searchController.clear();
          _searchFocusNode.unfocus();
          context.read<MapBloc>().add(MapPlaceSelected(item));
          _focusOnPlace(item);
        },
      );
    }).toSet();

    if (mounted) setState(() => _markers = markers);
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
    final controller = _mapController;
    if (controller == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await controller.setMapStyle(isDark ? _darkMapStyle : _lightMapStyle);
  }

  Future<void> _checkLocationPermission() async {
    final granted = await Geolocator.checkPermission() == LocationPermission.whileInUse || 
                    await Geolocator.checkPermission() == LocationPermission.always;
    if (!granted) {
      final requested = await Geolocator.requestPermission();
      context.read<MapBloc>().add(MapLocationPermissionUpdated(
        requested == LocationPermission.whileInUse || requested == LocationPermission.always
      ));
    } else {
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
      SandstormOverlay.show(context);
      await _flutterTts.setPitch(0.6);
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.speak("The desert consumes all.");
    }

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.18);

    Color chipBg({bool strong = false}) => surface.withOpacity(strong ? (isDark ? 0.92 : 0.95) : 0.92);

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Text('🎉 ', style: TextStyle(fontSize: 28)),
                  Text('You\'ve Arrived!'),
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
                myLocationEnabled: state.isLocationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
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
                  if (mounted) {
                    context.read<MapBloc>().add(MapZoomChanged(zoom));
                  }
                },
                onTap: (_) {
                  if (state.isSearchActive) {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  }
                  if (state.selectedPlace != null) {
                    context.read<MapBloc>().add(const MapPlaceSelected(null));
                  }
                },
              ),

              if (!state.isSearchActive && !state.isNavigationMode)
                Positioned(
                  top: 110,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: chipBg(),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))],
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_markers.length}/${state.allItems.length} places',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface.withOpacity(0.9)),
                        ),
                        if (state.selectedUiCategoryId != 'all')
                          Text(
                            MapConfig.categories.firstWhere((c) => c.id == state.selectedUiCategoryId, orElse: () => const UiCategory('', 'Unknown', '')).label,
                            style: TextStyle(fontSize: 10, color: primary, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),

              if (!state.isSearchActive && !state.isNavigationMode)
                Positioned(
                  top: 110,
                  right: 20,
                  child: Material(
                    color: state.selectedUiCategoryId == 'all' ? chipBg() : primary.withOpacity(isDark ? 0.90 : 0.95),
                    borderRadius: BorderRadius.circular(30),
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
                          context.read<MapBloc>().add(MapCategoryChanged(chosen));
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))],
                          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune,
                              color: state.selectedUiCategoryId == 'all' ? onSurface.withOpacity(0.9) : Colors.white,
                              size: 20,
                            ),
                            if (state.selectedUiCategoryId != 'all') ...[
                              const SizedBox(width: 6),
                              Text(
                                MapConfig.categories.firstWhere((c) => c.id == state.selectedUiCategoryId, orElse: () => const UiCategory('', '', '')).icon,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (!state.isSearchActive && !state.isNavigationMode)
                Positioned(
                  bottom: state.selectedPlace != null ? 420 : 180,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trip Planner
                      FloatingActionButton.small(
                        heroTag: "trip_planner_btn",
                        backgroundColor: chipBg(),
                        onPressed: () async {
                          final itinerary = await Navigator.push<List<MapItem>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripPlannerSheet(allItems: state.allItemsCache),
                            ),
                          );
                          if (itinerary != null && itinerary.isNotEmpty && mounted) {
                            setState(() {
                              _tripItinerary = itinerary;
                              _tripCurrentIndex = 0;
                            });
                            final firstStop = itinerary.first;
                            context.read<MapBloc>().add(MapPlaceSelected(firstStop));
                            _focusOnPlace(firstStop);
                            // Start directions to first stop
                            context.read<MapBloc>().add(
                              MapDirectionsRequested(
                                destination: firstStop,
                                apiKey: _directionsApiKey,
                                mode: state.selectedTravelMode,
                              ),
                            );
                          }
                        },
                        child: Icon(Icons.route_rounded, color: primary, size: 20),
                      ),
                      const SizedBox(height: 10),
                      // Near Me
                      FloatingActionButton.small(
                        heroTag: "near_me_btn",
                        backgroundColor: chipBg(),
                        onPressed: () async {
                          final selectedPlace = await showModalBottomSheet<MapItem>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => NearMeSheet(allItems: state.allItemsCache),
                          );
                          if (selectedPlace != null && mounted) {
                            context.read<MapBloc>().add(MapPlaceSelected(selectedPlace));
                            _focusOnPlace(selectedPlace);
                          }
                        },
                        child: Icon(Icons.near_me, color: primary, size: 20),
                      ),
                      const SizedBox(height: 10),
                      // Saved Places
                      FloatingActionButton(
                        heroTag: "saved_places_btn",
                        backgroundColor: chipBg(),
                        onPressed: () async {
                          final selectedPlace = await Navigator.push<MapItem>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SavedPlacesScreen(allItems: state.allItemsCache),
                            ),
                          );
                          if (selectedPlace != null && mounted) {
                            context.read<MapBloc>().add(MapPlaceSelected(selectedPlace));
                            _focusOnPlace(selectedPlace);
                          }
                        },
                        child: Icon(
                          Icons.bookmarks_rounded,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!state.isSearchActive)
                Positioned(
                  bottom: state.selectedPlace != null ? 350 : state.isNavigationMode ? 280 : 110,
                  right: 20,
                  child: FloatingActionButton(
                    heroTag: "location_btn",
                    backgroundColor: chipBg(),
                    onPressed: () => _goToUserLocation(state.isLocationPermissionGranted),
                    child: Icon(
                      Icons.my_location,
                      color: state.isLocationPermissionGranted ? primary : onSurface.withOpacity(0.9),
                    ),
                  ),
                ),

              if (state.selectedUiCategoryId != 'all' && !state.isSearchActive && !state.isNavigationMode)
                Positioned(
                  bottom: state.selectedPlace != null ? 350 : 110,
                  left: 20,
                  child: FloatingActionButton.extended(
                    heroTag: "reset_filter_btn",
                    backgroundColor: chipBg(),
                    onPressed: () => context.read<MapBloc>().add(const MapCategoryChanged('all')),
                    icon: Icon(Icons.close, color: onSurface.withOpacity(0.9), size: 18),
                    label: Text('Reset', style: TextStyle(color: onSurface.withOpacity(0.9))),
                  ),
                ),
              // Trip progress bar
              if (_isTripActive)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 75,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: chipBg(),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${_tripCurrentIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Stop ${_tripCurrentIndex + 1} of ${_tripItinerary.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _tripItinerary[_tripCurrentIndex].title,
                                style: TextStyle(
                                  fontSize: 15,
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Next Stop',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Done! 🎉',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _tripItinerary = [];
                              _tripCurrentIndex = -1;
                            });
                            context.read<MapBloc>().add(MapNavigationCleared());
                            context.read<MapBloc>().add(const MapPlaceSelected(null));
                          },
                          child: Icon(Icons.close, size: 20, color: onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                ),

              if (state.selectedPlace != null && !state.isNavigationMode)
                PlaceDetailSheet(
                  place: state.selectedPlace!,
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
                  bottom: 80, left: 0, right: 0,
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
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: shadowColor, blurRadius: 20, spreadRadius: 2, offset: const Offset(0, -4))],
                                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: primary)),
                                  const SizedBox(width: 14),
                                  Text('Finding route...', style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  Material(
                                    color: onSurface.withOpacity(0.08),
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.hardEdge,
                                    child: InkWell(
                                      onTap: () => context.read<MapBloc>().add(MapNavigationCleared()),
                                      customBorder: const CircleBorder(),
                                      child: SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6), size: 20),
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
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 16, spreadRadius: 1)],
                        border: Border.all(color: primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current step instruction
                          if (state.currentStepIndex < state.currentRoute!.steps.length) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.navigation_rounded, color: primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.currentRoute!.steps[state.currentStepIndex].instruction,
                                        style: TextStyle(
                                          color: onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                       const SizedBox(height: 4),
                                      Text(
                                        '${state.currentRoute!.steps[state.currentStepIndex].distance} · ${state.currentRoute!.steps[state.currentStepIndex].duration}',
                                        style: TextStyle(
                                          color: onSurface.withOpacity(0.5),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Overall ETA
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.flag_rounded, color: primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${state.currentRoute!.distance} · ${state.currentRoute!.duration} total',
                                    style: TextStyle(
                                      color: onSurface.withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Step progress bar
                            Row(
                              children: [
                                Text(
                                  'Step ${state.currentStepIndex + 1}/${state.currentRoute!.steps.length}',
                                  style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (state.currentStepIndex + 1) / state.currentRoute!.steps.length,
                                    backgroundColor: onSurface.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation(primary),
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.hardEdge,
                                  child: InkWell(
                                    onTap: () {
                                      _stopLiveNavigation();
                                      context.read<MapBloc>().add(MapNavigationCleared());
                                    },
                                    customBorder: const CircleBorder(),
                                    child: const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: Icon(Icons.stop_rounded, color: Colors.red, size: 18),
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
                  bottom: 30, right: 16,
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
                    child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                  ),
                ),

              if (state.isLoading)
                Positioned(
                  left: 0, right: 0, top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: chipBg(strong: true),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 16, offset: const Offset(0, 6))],
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
                              const SizedBox(width: 10),
                              Text("Loading...", style: TextStyle(color: onSurface.withOpacity(0.9))),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                    child: Container(color: Colors.black.withOpacity(0.25)),
                  ),
                ),

              if (!state.isLiveNavigating)
              Positioned(
                top: 50, left: 0, right: 0,
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
                        const SizedBox(height: 8),
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
}