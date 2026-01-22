import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import './data/map_repository.dart';
import '../home/data/models/map_item_models.dart';
import './domain/place_importance.dart';
import './services/marker_filter_service.dart';
// ✅ CRITICAL: Use the package import
import 'package:lost_in_egypt/feature/home/tabs/map/services/map_focus_service.dart';
import '../map/place_detail_screen.dart';

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
  
  // Setting this variable is what makes the Sheet slide up
  MapItem? _selectedItem;

  List<MapItem> _allItems = [];
  double _currentZoom = 10.0;
  String? _lightMapStyle;
  String _selectedUiCategoryId = 'all';

  static const CameraPosition _cairoPosition = CameraPosition(
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
    _UiCategory('restaurant', 'Restaurants'),
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadByCategory('all');
    
    // ⭐ LISTEN: When this screen wakes up, check if there is a place to focus on
    MapFocusService.instance.focusedItemNotifier.addListener(_onFocusRequest);
  }

  @override
  void dispose() {
    MapFocusService.instance.focusedItemNotifier.removeListener(_onFocusRequest);
    super.dispose();
  }

  // ⭐ THE ZOOM & OPEN LOGIC
  void _onFocusRequest() {
    final item = MapFocusService.instance.focusedItemNotifier.value;
    if (item != null) {
      print("🗺️ MAP: Zooming to ${item.title}");
      
      setState(() {
        _selectedItem = item; // This opens the Bottom Sheet
        
        // Ensure marker exists locally
        if (!_allItems.any((e) => e.id == item.id)) {
           _allItems.add(item);
        }
        _updateVisibleMarkers();
      });

      if (_mapController != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(item.coordinate.latitude, item.coordinate.longitude),
              zoom: 17, 
              tilt: 45, 
            ),
          ));
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _loadAndApplyMapStyleIfNeeded();

    // Check immediately if we need to zoom (in case map was just created)
    if (MapFocusService.instance.focusedItemNotifier.value != null) {
      _onFocusRequest();
    }
  }

  Future<void> _loadByCategory(String uiCategoryId) async {
    setState(() { _loading = true; _selectedUiCategoryId = uiCategoryId; });
    try {
      final items = await _repository.fetchByUiCategory(uiCategoryId);
      if(mounted) setState(() { _allItems = items; _updateVisibleMarkers(); });
    } catch (e) { debugPrint('Error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  void _updateVisibleMarkers() {
    if (_allItems.isEmpty) return;
    final filteredItems = MarkerFilterService.filterByZoom(_allItems, _currentZoom);
    setState(() {
      _markers = filteredItems.map((item) {
        final isSelected = item.id == _selectedItem?.id;
        return Marker(
          markerId: MarkerId(item.id),
          position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
          onTap: () => setState(() => _selectedItem = item),
          icon: BitmapDescriptor.defaultMarkerWithHue(isSelected ? BitmapDescriptor.hueRed : _hueFor(item)),
          zIndex: isSelected ? 2 : 1,
        );
      }).toSet();
    });
  }

  double _hueFor(MapItem item) {
    if (item.importance == PlaceImportance.landmark) return BitmapDescriptor.hueYellow;
    if (item.category.toLowerCase() == 'museum') return BitmapDescriptor.hueAzure;
    if (item.category.toLowerCase() == 'restaurant') return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueOrange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _cairoPosition,
            markers: _markers,
            myLocationEnabled: _isLocationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: _onMapCreated,
            onCameraMove: (pos) => _currentZoom = pos.zoom,
            onCameraIdle: _updateVisibleMarkers,
            padding: EdgeInsets.only(bottom: _selectedItem != null ? 300 : 0),
            onTap: (_) {
              setState(() => _selectedItem = null);
              MapFocusService.instance.clearFocus();
            },
          ),
          
          if (_selectedItem == null) ...[
            Positioned(
              top: 50, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: const Text("Lost In Egypt", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "Marcellus")),
                ),
              ),
            ),
            Positioned(
              top: 100, right: 20,
              child: FloatingActionButton(
                heroTag: "filter_btn",
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _openCategorySheet,
                child: const Icon(Icons.tune, color: Colors.black87),
              ),
            ),
            Positioned(
              bottom: 40, right: 20,
              child: FloatingActionButton(
                heroTag: "location_btn",
                backgroundColor: Colors.white,
                onPressed: _goToUserLocation,
                child: Icon(Icons.my_location, color: _isLocationPermissionGranted ? Colors.blue : Colors.black87),
              ),
            ),
          ],

          // ⭐ THE SLIDING SHEET
          if (_selectedItem != null)
            PlaceDetailSheet(
              place: _selectedItem!,
              onClose: () {
                setState(() => _selectedItem = null);
                MapFocusService.instance.clearFocus();
              },
              onShowOnMap: () {
                // Minimize sheet, user wants to see the map
              },
            ),

          if (_loading && _markers.isEmpty)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _loadAndApplyMapStyleIfNeeded() async {
    if (_lightMapStyle == null) {
      try { _lightMapStyle = await rootBundle.loadString('assets/map_style.json'); } catch(_) {}
    }
    if (_mapController != null && _lightMapStyle != null) _mapController!.setMapStyle(_lightMapStyle);
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      if (mounted) setState(() => _isLocationPermissionGranted = true);
    }
  }

  Future<void> _goToUserLocation() async {
    if (!_isLocationPermissionGranted) { await _checkLocationPermission(); if (!_isLocationPermissionGranted) return; }
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15)));
  }
  
  Future<void> _openCategorySheet() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text("Choose a Category", style: TextStyle(fontWeight: FontWeight.bold))),
          ..._categories.map((c) => ListTile(title: Text(c.label), trailing: c.id == _selectedUiCategoryId ? const Icon(Icons.check) : null, onTap: () => Navigator.pop(context, c.id))),
        ]));
      },
    );
    if (chosen != null) _loadByCategory(chosen);
  }
}

class _UiCategory {
  final String id;
  final String label;
  const _UiCategory(this.id, this.label);
}