import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import './data/map_repository.dart';
import '../home/data/models/map_item_models.dart';
import './domain/place_importance.dart';
import './services/marker_filter_service.dart';
import './services/map_focus_service.dart';
import './place_detail_screen.dart';

class _UiCategory {
  final String id;
  final String label;
  const _UiCategory(this.id, this.label);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapRepository _repository = MapRepository();
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  bool _isLocationPermissionGranted = false;
  bool _loading = false;

  String _selectedUiCategoryId = 'all';

  List<MapItem> _allItems = [];
  double _currentZoom = 10.0;

  MapItem? _selectedPlace;

  String? _lightMapStyle;
  String? _darkMapStyle;
  Brightness? _lastBrightness;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 10,
  );

  static const List<_UiCategory> _categories = [
    _UiCategory('all', 'All'),
    _UiCategory('landmark', 'Landmarks'),
    _UiCategory('museum', 'Museums'),
    _UiCategory('religious', 'Religious'),
    _UiCategory('nature', 'Nature'),
    _UiCategory('shopping', 'Shopping'),
    _UiCategory('restaurants', 'Restaurants'),
    _UiCategory('tourism', 'Tourism'),
    _UiCategory('hotel', 'Hotels'),
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadByCategory('all');
    MapFocusService.instance.focusedItemNotifier.addListener(_onFocusRequested);
  }

  @override
  void dispose() {
    MapFocusService.instance.focusedItemNotifier.removeListener(_onFocusRequested);
    super.dispose();
  }

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
    debugPrint('🎯 _focusOnPlace: ${place.title}');
    debugPrint('   📍 Lat: ${place.coordinate.latitude}, Lng: ${place.coordinate.longitude}');

    if (_mapController == null) {
      debugPrint('   ⏳ Waiting for map controller...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mapController == null) {
        debugPrint('   ❌ Map controller still null');
        return;
      }
    }

    if (!_allItems.any((p) => p.id == place.id)) {
      debugPrint('   ➕ Adding place to _allItems');
      _allItems.add(place);
    }

    setState(() {
      _selectedPlace = place;
    });

    debugPrint('   🎥 Animating camera...');
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(place.coordinate.latitude, place.coordinate.longitude),
            zoom: 17,
          ),
        ),
      );
      debugPrint('   ✅ Camera animation complete');
    } catch (e) {
      debugPrint('   ❌ Camera animation error: $e');
    }

    _currentZoom = 17;
    _updateVisibleMarkers(forceInclude: place);
    MapFocusService.instance.clearFocus();
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

  Future<void> _loadAndApplyMapStyleIfNeeded() async {
    if (_lightMapStyle == null) {
      _lightMapStyle = await rootBundle.loadString('assets/map_style.json');
    }
    if (_darkMapStyle == null) {
      try {
        _darkMapStyle = await rootBundle.loadString('assets/map_style_dark.json');
      } catch (_) {
        _darkMapStyle = _lightMapStyle;
      }
    }
    await _applyCurrentMapStyle();
  }

  Future<void> _applyCurrentMapStyle() async {
    final controller = _mapController;
    if (controller == null) return;
    final isDark = (Theme.of(context).brightness == Brightness.dark);
    final style = isDark ? _darkMapStyle : _lightMapStyle;
    if (style != null) {
      await controller.setMapStyle(style);
    }
  }

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

  Future<void> _loadFeatured() async {
    setState(() {
      _loading = true;
      _selectedUiCategoryId = 'recommended';
    });

    final items = await _repository.fetchFeaturedMapItems(limit: 80);
    _allItems = items;
    _updateVisibleMarkers();
    _debugImportanceBreakdown();

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadByCategory(String uiCategoryId) async {
    setState(() {
      _loading = true;
      _selectedUiCategoryId = uiCategoryId;
    });

    final limit = uiCategoryId == 'all' ? 2000 : 500;
    final items = await _repository.fetchByUiCategory(uiCategoryId, limit: limit);

    _allItems = items;
    _updateVisibleMarkers();
    _debugImportanceBreakdown();

    if (mounted) setState(() => _loading = false);
  }

  void _debugImportanceBreakdown() {
    final breakdown = MarkerFilterService.getImportanceBreakdown(_allItems);
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 IMPORTANCE BREAKDOWN (Total: ${_allItems.length})');
    debugPrint('───────────────────────────────────────');
    debugPrint('   (10 = Most Important, 1 = Least Important)');
    debugPrint('───────────────────────────────────────');
    for (int i = 10; i >= 1; i--) {
      final count = breakdown[i] ?? 0;
      final label = ImportanceConfig.getLabelForImportance(i);
      final minZoom = ImportanceConfig.getMinZoomForImportance(i);
      final bar = '█' * (count ~/ 30);
      debugPrint('   $i - $label: $count (zoom >= $minZoom) $bar');
    }
    debugPrint('═══════════════════════════════════════');
  }

  void _updateVisibleMarkers({MapItem? forceInclude}) {
    if (_allItems.isEmpty && forceInclude == null) {
      setState(() => _markers = {});
      debugPrint('⚠️ No items to display');
      return;
    }

    var filteredItems = MarkerFilterService.filterByZoom(_allItems, _currentZoom);

    if (forceInclude != null && !filteredItems.any((p) => p.id == forceInclude.id)) {
      filteredItems = [...filteredItems, forceInclude];
      debugPrint('   ➕ Force included: ${forceInclude.title}');
    }

    final markers = filteredItems.map((item) {
      final isSelected = _selectedPlace?.id == item.id;
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: '${item.category.toUpperCase()} • ${item.importance.importanceLabel}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : _hueFor(item),
        ),
        onTap: () => _onMarkerTapped(item),
      );
    }).toSet();

    if (mounted) {
      setState(() => _markers = markers);
    }

    debugPrint('📍 Zoom: ${_currentZoom.toStringAsFixed(1)} | Showing: ${markers.length}/${_allItems.length}');
  }

  void _onMarkerTapped(MapItem place) {
    debugPrint('📍 Marker tapped: ${place.title}');
    setState(() {
      _selectedPlace = place;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(place.coordinate.latitude, place.coordinate.longitude),
      ),
    );
  }

  void _closeDetailSheet() {
    setState(() {
      _selectedPlace = null;
    });
    _updateVisibleMarkers();
  }

  double _hueFor(MapItem item) {
    final importance = item.importance;
    final category = item.category.toLowerCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toSet();

    if (importance >= 9) {
      return BitmapDescriptor.hueYellow;
    }

    if (category == 'event' || tags.contains('event')) {
      return BitmapDescriptor.hueViolet;
    }
    if (category == 'museum' || tags.contains('museum')) {
      return BitmapDescriptor.hueAzure;
    }
    if (category == 'religious' || tags.contains('mosque') || tags.contains('church')) {
      return BitmapDescriptor.hueGreen;
    }
    if (category == 'hotel' || tags.contains('hotel') || tags.contains('accommodation')) {
      return BitmapDescriptor.hueMagenta;
    }
    if (category == 'tourism') {
      return BitmapDescriptor.hueCyan;
    }
    if (tags.contains('restaurant') || tags.contains('food')) {
      return BitmapDescriptor.hueRed;
    }
    if (tags.contains('market') || tags.contains('shopping')) {
      return BitmapDescriptor.hueOrange;
    }

    if (importance >= 8) return BitmapDescriptor.hueRed;
    if (importance >= 6) return BitmapDescriptor.hueOrange;
    if (importance >= 4) return BitmapDescriptor.hueRose;
    if (importance >= 2) return BitmapDescriptor.hueCyan;
    return BitmapDescriptor.hueBlue;
  }

  Future<void> _openCategorySheet() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  "Choose a Category",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._categories.map((c) {
                final selected = c.id == _selectedUiCategoryId;
                return ListTile(
                  title: Text(c.label),
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, c.id),
                );
              }),
            ],
          ),
        );
      },
    );

    if (chosen == null) return;
    if (chosen == 'recommended') {
      await _loadFeatured();
    } else {
      await _loadByCategory(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: _isLocationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              debugPrint('🗺️ Map created!');
              _mapController = controller;
              await _loadAndApplyMapStyleIfNeeded();

              final pendingFocus = MapFocusService.instance.focusedItemNotifier.value;
              if (pendingFocus != null) {
                debugPrint('🎯 Processing pending focus: ${pendingFocus.title}');
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
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Text(
                  "Lost In Egypt",
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "Marcellus"),
                ),
              ),
            ),
          ),
          Positioned(
            top: 110,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Text(
                '${_markers.length}/${_allItems.length} places',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Positioned(
            top: 110,
            right: 20,
            child: FloatingActionButton(
              heroTag: "filter_btn",
              backgroundColor: Colors.white,
              onPressed: _openCategorySheet,
              child: const Icon(Icons.tune, color: Colors.black87),
            ),
          ),
          Positioned(
            bottom: _selectedPlace != null ? 350 : 110,
            right: 20,
            child: FloatingActionButton(
              heroTag: "location_btn",
              backgroundColor: Colors.white,
              onPressed: () {
                if (_isLocationPermissionGranted) {
                  _goToUserLocation();
                } else {
                  _checkLocationPermission();
                }
              },
              child: Icon(
                Icons.my_location,
                color: _isLocationPermissionGranted ? Colors.blue : Colors.black87,
              ),
            ),
          ),
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
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text("Loading..."),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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