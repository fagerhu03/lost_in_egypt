import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import './data/map_repository.dart';
import '../home/data/models/map_item_models.dart';
import './services/marker_filter_service.dart';
import './services/map_focus_service.dart';
import './services/map_marker_service.dart';
import './place_detail_screen.dart';
import './map_config.dart';
import './widgets/map_filter_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapRepository _repository = MapRepository();
  final MapMarkerService _markerService = MapMarkerService();

  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  bool _isLocationPermissionGranted = false;
  bool _loading = false;

  String _selectedUiCategoryId = 'all';

  List<MapItem> _allItems = [];
  List<MapItem> _allItemsCache = [];
  double _currentZoom = 10.0;

  MapItem? _selectedPlace;

  // ─────────────────────────────────────────────
  // Map styles (Light / Dark)
  // Files expected:
  //   assets/map_style.json
  //   assets/darkmode_map_style.json
  // ─────────────────────────────────────────────
  String? _lightMapStyle;
  String? _darkMapStyle;
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _markerService.loadCustomMarkerIcons();
    await _checkLocationPermission();
    await _loadByCategory('all');

    MapFocusService.instance.focusedItemNotifier.addListener(_onFocusRequested);
  }

  @override
  void dispose() {
    MapFocusService.instance.focusedItemNotifier.removeListener(_onFocusRequested);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Re-apply style if theme brightness changed (light <-> dark)
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _loadAndApplyMapStyleIfNeeded();
    }
  }

  bool _shouldShowItem(MapItem item) {
    return !MapConfig.excludedCategories.contains(item.category.toLowerCase());
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 MARKER UPDATE METHOD
  // ═══════════════════════════════════════════════════════════

  void _updateVisibleMarkers({MapItem? forceInclude}) {
    if (_allItems.isEmpty && forceInclude == null) {
      if (mounted) setState(() => _markers = {});
      debugPrint('⚠️ No items to display');
      return;
    }

    List<MapItem> filteredItems;

    if (_selectedUiCategoryId == 'all') {
      filteredItems = MarkerFilterService.filterByZoom(_allItems, _currentZoom);
      debugPrint(
        '🔍 Filter: ALL with zoom filtering (zoom: ${_currentZoom.toStringAsFixed(1)})',
      );
    } else {
      filteredItems = List.from(_allItems);
      debugPrint('🔍 Filter: Category "$_selectedUiCategoryId" - NO zoom filtering');
    }

    filteredItems = filteredItems.where(_shouldShowItem).toList();

    if (forceInclude != null && !filteredItems.any((p) => p.id == forceInclude.id)) {
      if (_shouldShowItem(forceInclude)) {
        filteredItems = [...filteredItems, forceInclude];
        debugPrint('   ➕ Force included: ${forceInclude.title}');
      }
    }

    final markers = filteredItems.map((item) {
      final isSelected = _selectedPlace?.id == item.id;

      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: item.category.toUpperCase(),
        ),
        icon: _markerService.getMarkerIconByCategory(item, isSelected),
        anchor: const Offset(0.5, 1.0),
        onTap: () => _onMarkerTapped(item),
      );
    }).toSet();

    if (mounted) setState(() => _markers = markers);

    debugPrint('📍 Showing: ${markers.length}/${_allItems.length} places');
  }

  // ═══════════════════════════════════════════════════════════
  // 📍 FOCUS & NAVIGATION METHODS
  // ═══════════════════════════════════════════════════════════

  void _onFocusRequested() {
    final item = MapFocusService.instance.focusedItemNotifier.value;
    if (item != null && mounted) {
      debugPrint('📷 Focus requested for: ${item.title}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnPlace(item);
      });
    }
  }

  Future<void> _focusOnPlace(MapItem place) async {
    if (_mapController == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mapController == null) return;
    }

    if (!_allItems.any((p) => p.id == place.id)) {
      _allItems.add(place);
    }

    if (mounted) {
      setState(() {
        _selectedPlace = place;
      });
    }

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(place.coordinate.latitude, place.coordinate.longitude),
            zoom: 17,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Camera animation error: $e');
    }

    _currentZoom = 17;
    _updateVisibleMarkers(forceInclude: place);
    MapFocusService.instance.clearFocus();
  }

  // ═══════════════════════════════════════════════════════════
  // 🎨 MAP STYLE METHODS (Light/Dark)
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadAndApplyMapStyleIfNeeded() async {
    // Load once & cache
    _lightMapStyle ??= await rootBundle.loadString('assets/map_style.json');

    if (_darkMapStyle == null) {
      try {
        _darkMapStyle =
            await rootBundle.loadString('assets/darkmode_map_style.json');
      } catch (_) {
        // If the dark file is missing, fallback to light style
        _darkMapStyle = _lightMapStyle;
      }
    }

    await _applyCurrentMapStyle();
  }

  Future<void> _applyCurrentMapStyle() async {
    final controller = _mapController;
    if (controller == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = isDark ? _darkMapStyle : _lightMapStyle;

    if (style != null) {
      await controller.setMapStyle(style);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📍 LOCATION PERMISSION METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _isLocationPermissionGranted = true);
    }
  }

  Future<void> _goToUserLocation() async {
    if (!_isLocationPermissionGranted) {
      await _checkLocationPermission();
      if (!_isLocationPermissionGranted) return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📦 DATA LOADING METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadAllItemsIfNeeded() async {
    if (_allItemsCache.isEmpty) {
      _allItemsCache = await _repository.fetchByUiCategory('all', limit: 3000);
      _debugAvailableCategories();
    }
  }

  void _debugAvailableCategories() {
    final categories = <String, int>{};
    for (final item in _allItemsCache) {
      final cat = item.category.toLowerCase();
      categories[cat] = (categories[cat] ?? 0) + 1;
    }
    debugPrint('═══════════════════════════════════════');
    debugPrint('📂 AVAILABLE CATEGORIES IN DATA:');
    categories.forEach((key, value) {
      debugPrint('   $key: $value items');
    });
    debugPrint('═══════════════════════════════════════');
  }

  Future<void> _loadByCategory(String uiCategoryId) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _selectedUiCategoryId = uiCategoryId;
      });
    }

    await _loadAllItemsIfNeeded();

    List<MapItem> items;

    if (uiCategoryId == 'all') {
      items = _allItemsCache.where(_shouldShowItem).toList();
    } else {
      items = _allItemsCache.where((item) {
        final itemCategory = item.category.toLowerCase().trim();
        final filterCategory = uiCategoryId.toLowerCase().trim();
        return itemCategory == filterCategory;
      }).toList();
    }

    _allItems = items;
    _updateVisibleMarkers();

    if (mounted) setState(() => _loading = false);
  }

  // ═══════════════════════════════════════════════════════════
  // 🖱️ INTERACTION METHODS
  // ═══════════════════════════════════════════════════════════

  void _onMarkerTapped(MapItem place) {
    if (mounted) setState(() => _selectedPlace = place);

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(place.coordinate.latitude, place.coordinate.longitude),
      ),
    );
  }

  void _closeDetailSheet() {
    if (mounted) setState(() => _selectedPlace = null);
    _updateVisibleMarkers();
  }

  Future<void> _openCategorySheet() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return MapFilterSheet(
          selectedCategory: _selectedUiCategoryId,
          allItems: _allItemsCache,
          onCategorySelected: (category) => Navigator.pop(context, category),
        );
      },
    );

    if (chosen == null) return;
    await _loadByCategory(chosen);
  }

  // ═══════════════════════════════════════════════════════════
  // 🏗️ BUILD METHOD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.18);

    Color chipBg({bool strong = false}) {
      final base = surface.withOpacity(strong ? (isDark ? 0.92 : 0.95) : 0.92);
      return base;
    }

    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ GOOGLE MAP
          GoogleMap(
            initialCameraPosition: MapConfig.initialPosition,
            markers: _markers,
            myLocationEnabled: _isLocationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
              await _loadAndApplyMapStyleIfNeeded();

              final pendingFocus = MapFocusService.instance.focusedItemNotifier.value;
              if (pendingFocus != null) {
                _focusOnPlace(pendingFocus);
              }
            },
            onCameraMove: (position) {
              _currentZoom = position.zoom;
            },
            onCameraIdle: () {
              _updateVisibleMarkers(forceInclude: _selectedPlace);
            },
            onTap: (_) {
              if (_selectedPlace != null) {
                _closeDetailSheet();
              }
            },
          ),

          // 🏷️ APP TITLE
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: chipBg(strong: true),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  ),
                ),
                child: Text(
                  "Lost In Egypt",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Marcellus",
                    color: onSurface.withOpacity(0.95),
                  ),
                ),
              ),
            ),
          ),

          // 📊 PLACE COUNT & CURRENT FILTER
          Positioned(
            top: 110,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_markers.length}/${_allItems.length} places',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withOpacity(0.9),
                    ),
                  ),
                  if (_selectedUiCategoryId != 'all')
                    Text(
                      MapConfig.categories
                          .firstWhere(
                            (c) => c.id == _selectedUiCategoryId,
                            orElse: () => const UiCategory('', 'Unknown', ''),
                          )
                          .label,
                      style: TextStyle(
                        fontSize: 10,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 🔧 FILTER BUTTON
          Positioned(
            top: 110,
            right: 20,
            child: GestureDetector(
              onTap: _openCategorySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedUiCategoryId == 'all'
                      ? chipBg()
                      : primary.withOpacity(isDark ? 0.90 : 0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      color: _selectedUiCategoryId == 'all'
                          ? onSurface.withOpacity(0.9)
                          : Colors.white,
                      size: 20,
                    ),
                    if (_selectedUiCategoryId != 'all') ...[
                      const SizedBox(width: 6),
                      Text(
                        MapConfig.categories
                            .firstWhere(
                              (c) => c.id == _selectedUiCategoryId,
                              orElse: () => const UiCategory('', '', ''),
                            )
                            .icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 📍 MY LOCATION BUTTON
          Positioned(
            bottom: _selectedPlace != null ? 350 : 110,
            right: 20,
            child: FloatingActionButton(
              heroTag: "location_btn",
              backgroundColor: surface.withOpacity(isDark ? 0.92 : 0.95),
              onPressed: () {
                if (_isLocationPermissionGranted) {
                  _goToUserLocation();
                } else {
                  _checkLocationPermission();
                }
              },
              child: Icon(
                Icons.my_location,
                color: _isLocationPermissionGranted
                    ? primary
                    : onSurface.withOpacity(0.9),
              ),
            ),
          ),

          // 🔄 RESET FILTER BUTTON
          if (_selectedUiCategoryId != 'all')
            Positioned(
              bottom: _selectedPlace != null ? 350 : 110,
              left: 20,
              child: FloatingActionButton.extended(
                heroTag: "reset_filter_btn",
                backgroundColor: surface.withOpacity(isDark ? 0.92 : 0.95),
                onPressed: () => _loadByCategory('all'),
                icon: Icon(Icons.close, color: onSurface.withOpacity(0.9), size: 18),
                label: Text(
                  'Reset',
                  style: TextStyle(color: onSurface.withOpacity(0.9)),
                ),
              ),
            ),

          // ⏳ LOADING INDICATOR
          if (_loading)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: chipBg(strong: true),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Loading...",
                            style: TextStyle(color: onSurface.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 📋 PLACE DETAIL SHEET
          if (_selectedPlace != null)
            PlaceDetailSheet(
              place: _selectedPlace!,
              onClose: _closeDetailSheet,
              onShowOnMap: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      _selectedPlace!.coordinate.latitude,
                      _selectedPlace!.coordinate.longitude,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}