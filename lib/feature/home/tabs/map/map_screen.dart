import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import './data/map_repository.dart';
import '../home/data/models/map_item_models.dart';

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

  // Default selection: recommended only
  String _selectedUiCategoryId = 'all';

  // ---- Map Styling (assets) ----
  String? _lightMapStyle;
  String? _darkMapStyle;
  Brightness? _lastBrightness;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 10,
  );

  static const List<_UiCategory> _categories = [
    _UiCategory('all', 'All'),
    _UiCategory('landmark', 'Landmarks'),   // Was 'historic'
    _UiCategory('museum', 'Museums'),
    _UiCategory('religious', 'Religious'),  // For Mosques/Churches
    _UiCategory('nature', 'Nature'),        // For Parks
    _UiCategory('shopping', 'Shopping'),    // For Markets
    
    // Keep these if you plan to add them later manually
    _UiCategory('restaurants', 'Restaurants'),
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    // WAS: _loadFeatured();
    // NOW: Load everything immediately
    _loadByCategory('all'); 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Called when theme/locale/etc changes.
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
        // Fallback to light style if dark file doesn't exist yet
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
    _setMarkersFromItems(items);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadByCategory(String uiCategoryId) async {
    setState(() {
      _loading = true;
      _selectedUiCategoryId = uiCategoryId;
    });

    // For "all", you may want a smaller/larger limit
    final limit = uiCategoryId == 'all' ? 500 : 250;

    final items = await _repository.fetchByUiCategory(uiCategoryId, limit: limit);
    _setMarkersFromItems(items);

    if (mounted) setState(() => _loading = false);
  }

  void _setMarkersFromItems(List<MapItem> items) {
    final markers = items.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: item.category.toUpperCase(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(item)),
      );
    }).toSet();

    if (mounted) setState(() => _markers = markers);
  }

  double _hueFor(MapItem item) {
    final tags = item.tags.map((t) => t.toLowerCase()).toSet();
    final category = item.category.toLowerCase();

    if (tags.contains('recommended') ||
        tags.contains('featured') ||
        tags.contains('top_pick')) {
      return BitmapDescriptor.hueYellow;
    }
    if (category == 'event' || tags.contains('event')) return BitmapDescriptor.hueViolet;
    if (tags.contains('nightlife') || tags.contains('bar') || tags.contains('club')) {
      return BitmapDescriptor.hueRose;
    }
    if (category == 'museum' || tags.contains('museum')) return BitmapDescriptor.hueAzure;
    if (category == 'market' || tags.contains('market') || tags.contains('souq')) {
      return BitmapDescriptor.hueOrange;
    }
    if (tags.contains('historic') || tags.contains('pyramid') || tags.contains('unesco')) {
      return BitmapDescriptor.hueOrange;
    }
    if (tags.contains('restaurant') || tags.contains('food')) {
      return BitmapDescriptor.hueRed;
    }
    return BitmapDescriptor.hueRed;
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

              // Load/apply style when the map is created
              await _loadAndApplyMapStyleIfNeeded();
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

          // Re-center button
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