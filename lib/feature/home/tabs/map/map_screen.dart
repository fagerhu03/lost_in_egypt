import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; 
import './data/map_repository.dart';
import '../home/data/models/map_item_models.dart'; 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapRepository _repository = MapRepository();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // ⭐ Variable to track if we can show the Blue Dot
  bool _isLocationPermissionGranted = false;

  // Starting position (Cairo)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 10,
  );

  final String _mapStyle = '''
    [
      {
        "featureType": "poi",
        "stylers": [{"visibility": "on"}] 
      },
      {
        "featureType": "transit",
        "stylers": [{"visibility": "off"}]
      }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    _loadMapItems();
    _checkLocationPermission(); // ⭐ Check permission on start
  }

  // ⭐ 1. CHECK PERMISSION LOGIC
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      setState(() {
        _isLocationPermissionGranted = true;
      });
    }
  }

  // ⭐ 2. GET USER LOCATION & MOVE CAMERA
  Future<void> _goToUserLocation() async {
    // Check permission again just in case
    if (!_isLocationPermissionGranted) {
      await _checkLocationPermission();
      if (!_isLocationPermissionGranted) return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Move Camera
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _loadMapItems() async {
    final List<MapItem> items = await _repository.fetchAllMapItems();

    final markers = items.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.coordinate.latitude, item.coordinate.longitude),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: item.category.toUpperCase(),
          onTap: () {
             // Navigation logic here...
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          item.category == 'event' 
              ? BitmapDescriptor.hueViolet 
              : BitmapDescriptor.hueOrange,
        ),
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _markers = markers;
      });
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
            
            // ⭐ DYNAMICALLY ENABLE BLUE DOT
            myLocationEnabled: _isLocationPermissionGranted, 
            
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(_mapStyle);
            },
          ),

          // RE-CENTER BUTTON
          Positioned(
            bottom: 110,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location, 
                // Color change to show active state
                color: _isLocationPermissionGranted ? Colors.blue : Colors.black87
              ),
              onPressed: () {
                if (_isLocationPermissionGranted) {
                  _goToUserLocation(); // Fly to user
                } else {
                  _checkLocationPermission(); // Ask again
                }
              },
            ),
          ),
          
          // TITLE OVERLAY
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
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Text(
                  "Lost In Egypt",
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "Marcellus"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}