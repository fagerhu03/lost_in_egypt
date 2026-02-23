import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/di/service_locator.dart';
import '../home/data/models/map_item_models.dart';
import './services/marker_filter_service.dart';
import './services/map_focus_service.dart';
import './services/map_marker_service.dart';
import './models/route_info.dart';
import './place_detail_screen.dart';
import './map_config.dart';
import './widgets/map_filter_sheet.dart';
import './widgets/navigation_info_bar.dart';
import './widgets/route_steps_sheet.dart';
import './widgets/map_search_bar.dart';
import './widgets/map_search_results.dart';

import 'bloc/map_bloc.dart';
import 'bloc/map_event.dart';
import 'bloc/map_state.dart';

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
      dotenv.env['GOOGLE_CLOUD_VISION_API_KEY'] ?? '';

  final MapMarkerService _markerService = MapMarkerService();
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String? _lightMapStyle;
  String? _darkMapStyle;
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    _initializeMapServices();

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
  }

  @override
  void dispose() {
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

    List<MapItem> filteredItems;
    if (state.selectedUiCategoryId == 'all') {
      filteredItems = MarkerFilterService.filterByZoom(state.allItems, state.currentZoom);
    } else {
      filteredItems = List.from(state.allItems);
    }

    if (forceInclude != null && !filteredItems.any((p) => p.id == forceInclude.id)) {
      filteredItems = [...filteredItems, forceInclude];
    }

    final markers = filteredItems.map((item) {
      final isSelected = state.selectedPlace?.id == item.id;
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: item.category.toUpperCase(),
        ),
        icon: _markerService.getMarkerIconByCategory(item, isSelected),
        anchor: const Offset(0.5, 1.0),
        onTap: () {
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
      return;
    }

    final polyline = Polyline(
      polylineId: const PolylineId('navigation_route'),
      points: state.currentRoute!.polylinePoints,
      color: Theme.of(context).colorScheme.primary,
      width: 5,
      patterns: state.selectedTravelMode == 'walking'
          ? [PatternItem.dot, PatternItem.gap(10)]
          : [],
    );

    if (mounted) setState(() => _polylines = {polyline});
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(state.currentRoute!.bounds, 80),
    );
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

  Future<void> _openGoogleMapsNavigation(MapState state) async {
    if (state.navigationDestination == null) return;
    final destLat = state.navigationDestination!.coordinate.latitude;
    final destLng = state.navigationDestination!.coordinate.longitude;

    final mode = state.selectedTravelMode == 'driving' ? 'd' : (state.selectedTravelMode == 'walking' ? 'w' : 'r');
    final url = Uri.parse('google.navigation:q=$destLat,$destLng&mode=$mode');
    final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=${state.selectedTravelMode}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launchUrl(webUrl, mode: LaunchMode.externalApplication);
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
               previous.error != current.error;
      },
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
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
                onCameraMove: (position) {
                  context.read<MapBloc>().add(MapZoomChanged(position.zoom));
                },
                onCameraIdle: () {
                  _updateVisibleMarkers(state, forceInclude: state.selectedPlace);
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
                  child: GestureDetector(
                    onTap: () async {
                      final chosen = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: surface,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => MapFilterSheet(
                          selectedCategory: state.selectedUiCategoryId,
                          allItems: state.allItemsCache,
                          onCategorySelected: (category) => Navigator.pop(context, category),
                        ),
                      );
                      if (chosen != null) {
                        context.read<MapBloc>().add(MapCategoryChanged(chosen));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: state.selectedUiCategoryId == 'all' ? chipBg() : primary.withOpacity(isDark ? 0.90 : 0.95),
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

              if (state.selectedPlace != null && !state.isNavigationMode)
                PlaceDetailSheet(
                  place: state.selectedPlace!,
                  onClose: () => context.read<MapBloc>().add(const MapPlaceSelected(null)),
                  onShowOnMap: () => _focusOnPlace(state.selectedPlace!),
                  onDirections: () => context.read<MapBloc>().add(
                    MapDirectionsRequested(
                      destination: state.selectedPlace!,
                      apiKey: _directionsApiKey,
                      mode: state.selectedTravelMode,
                    ),
                  ),
                ),

              if (state.isNavigationMode)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: state.currentRoute != null
                      ? NavigationInfoBar(
                          routeInfo: state.currentRoute!,
                          selectedMode: state.selectedTravelMode,
                          isLoadingRoute: state.isLoadingRoute,
                          onClose: () => context.read<MapBloc>().add(MapNavigationCleared()),
                          onStartNavigation: () => _openGoogleMapsNavigation(state),
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
                                  GestureDetector(
                                    onTap: () => context.read<MapBloc>().add(MapNavigationCleared()),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: onSurface.withOpacity(0.08), shape: BoxShape.circle),
                                      child: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6), size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
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

              Positioned(
                top: 50, left: 0, right: 0,
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
            ],
          ),
        );
      },
    );
  }
}