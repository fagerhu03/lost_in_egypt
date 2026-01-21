import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './data/map_repository.dart';
import '../home/data/models/map_item_models.dart';

// Importance system imports
import './domain/place_importance.dart';
import './domain/importance_calculator.dart';
import './services/marker_filter_service.dart';

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

  // Store all items and current zoom
  List<MapItem> _allItems = [];
  double _currentZoom = 10.0;

  // Map Styling
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
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    
    // 🔍 DEBUG TEST: Direct Firestore query
    _testFirestore();
    
    _loadByCategory('all');
  }

  // 🔍 TEMPORARY TEST METHOD - Remove after debugging
  Future<void> _testFirestore() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🧪 STARTING FIRESTORE TEST...');
    debugPrint('═══════════════════════════════════════');
    
    try {
      // Test 1: Check 'places' collection
      final placesSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .limit(5)
          .get();
      
      debugPrint('📁 "places" collection: ${placesSnapshot.docs.length} documents found');
      
      for (final doc in placesSnapshot.docs) {
        final data = doc.data();
        debugPrint('   📄 ${doc.id}:');
        debugPrint('      title: ${data['title']}');
        debugPrint('      category: ${data['category']}');
      }

      // Test 2: Check if there are other collections
      debugPrint('');
      debugPrint('🔍 Trying alternative collection names...');
      
      // Try 'Places' (capitalized)
      final placesCapSnapshot = await FirebaseFirestore.instance
          .collection('Places')
          .limit(3)
          .get();
      debugPrint('   📁 "Places" (capitalized): ${placesCapSnapshot.docs.length} documents');

      // Try 'locations'
      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .limit(3)
          .get();
      debugPrint('   📁 "locations": ${locationsSnapshot.docs.length} documents');

      // Try 'mapItems'
      final mapItemsSnapshot = await FirebaseFirestore.instance
          .collection('mapItems')
          .limit(3)
          .get();
      debugPrint('   📁 "mapItems": ${mapItemsSnapshot.docs.length} documents');

    } catch (e) {
      debugPrint('❌ FIRESTORE TEST ERROR: $e');
    }
    
    debugPrint('═══════════════════════════════════════');
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
    debugPrint('');
    debugPrint('🔄 _loadFeatured() called...');
    
    setState(() {
      _loading = true;
      _selectedUiCategoryId = 'recommended';
    });

    try {
      final items = await _repository.fetchFeaturedMapItems(limit: 80);
      
      debugPrint('✅ fetchFeaturedMapItems returned ${items.length} items');
      
      if (items.isNotEmpty) {
        debugPrint('📦 First item: ${items.first.title}');
        debugPrint('📦 Last item: ${items.last.title}');
      } else {
        debugPrint('⚠️ WARNING: fetchFeaturedMapItems returned EMPTY list!');
      }

      _allItems = items;
      _updateVisibleMarkers();
      
    } catch (e) {
      debugPrint('❌ ERROR in _loadFeatured: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadByCategory(String uiCategoryId) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔄 _loadByCategory("$uiCategoryId") called...');
    
    setState(() {
      _loading = true;
      _selectedUiCategoryId = uiCategoryId;
    });

    final limit = uiCategoryId == 'all' ? 500 : 250;
    debugPrint('📊 Limit set to: $limit');

    try {
      debugPrint('⏳ Calling repository.fetchByUiCategory...');
      
      final items = await _repository.fetchByUiCategory(uiCategoryId, limit: limit);
      
      debugPrint('✅ fetchByUiCategory returned ${items.length} items');
      
      if (items.isNotEmpty) {
        debugPrint('📦 First item: ${items.first.title} (${items.first.category})');
        debugPrint('📦 Last item: ${items.last.title} (${items.last.category})');
        
        // Show category breakdown
        final categoryCount = <String, int>{};
        for (final item in items) {
          categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
        }
        debugPrint('📊 Category breakdown:');
        categoryCount.forEach((cat, count) {
          debugPrint('   • $cat: $count');
        });
      } else {
        debugPrint('⚠️ WARNING: fetchByUiCategory returned EMPTY list!');
        debugPrint('💡 Check your MapRepository.fetchByUiCategory method');
      }

      _allItems = items;
      _updateVisibleMarkers();
      
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in _loadByCategory: $e');
      debugPrint('📜 Stack trace: $stackTrace');
    }

    if (mounted) setState(() => _loading = false);
    debugPrint('═══════════════════════════════════════');
  }

  void _updateVisibleMarkers() {
    debugPrint('');
    debugPrint('🔄 _updateVisibleMarkers() called');
    debugPrint('   _allItems.length = ${_allItems.length}');
    debugPrint('   _currentZoom = $_currentZoom');
    
    if (_allItems.isEmpty) {
      debugPrint('⚠️ Cannot update markers - _allItems is EMPTY!');
      setState(() => _markers = {});
      return;
    }

    final filteredItems = MarkerFilterService.filterByZoom(
      _allItems,
      _currentZoom,
    );

    debugPrint('📍 After filtering: ${filteredItems.length} items visible');

    // Debug: Show importance breakdown
    final importanceCount = <PlaceImportance, int>{};
    for (final item in _allItems) {
      importanceCount[item.importance] = (importanceCount[item.importance] ?? 0) + 1;
    }
    debugPrint('📊 Importance breakdown (all items):');
    importanceCount.forEach((imp, count) {
      debugPrint('   • ${imp.label}: $count (min zoom: ${imp.minZoomLevel})');
    });

    final markers = filteredItems.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: '${item.category.toUpperCase()} • ${item.importance.label}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(item)),
      );
    }).toSet();

    if (mounted) {
      setState(() => _markers = markers);
    }

    debugPrint('📍 Zoom: ${_currentZoom.toStringAsFixed(1)} | Showing: ${markers.length}/${_allItems.length}');
  }

  double _hueFor(MapItem item) {
    final importance = item.importance;

    // Landmarks get gold color
    if (importance == PlaceImportance.landmark) {
      return BitmapDescriptor.hueYellow;
    }

    final tags = item.tags.map((t) => t.toLowerCase()).toSet();
    final category = item.category.toLowerCase();

    if (tags.contains('recommended') || tags.contains('featured')) {
      return BitmapDescriptor.hueYellow;
    }
    if (category == 'event' || tags.contains('event')) {
      return BitmapDescriptor.hueViolet;
    }
    if (category == 'museum' || tags.contains('museum')) {
      return BitmapDescriptor.hueAzure;
    }
    if (category == 'market' || tags.contains('souq')) {
      return BitmapDescriptor.hueOrange;
    }
    if (tags.contains('restaurant') || tags.contains('food')) {
      return BitmapDescriptor.hueRed;
    }

    // Color by importance
    switch (importance) {
      case PlaceImportance.major:
        return BitmapDescriptor.hueRed;
      case PlaceImportance.moderate:
        return BitmapDescriptor.hueOrange;
      case PlaceImportance.minor:
        return BitmapDescriptor.hueCyan;
      default:
        return BitmapDescriptor.hueRed;
    }
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
              _mapController = controller;
              await _loadAndApplyMapStyleIfNeeded();
            },
            onCameraMove: (position) {
              _currentZoom = position.zoom;
            },
            onCameraIdle: () {
              _updateVisibleMarkers();
            },
          ),

          // Title
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

          // Marker count indicator
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

          // Filter button
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

          // Location button
          Positioned(
            bottom: 110,
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

          // Loading overlay
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
        ],
      ),
    );
  }
}