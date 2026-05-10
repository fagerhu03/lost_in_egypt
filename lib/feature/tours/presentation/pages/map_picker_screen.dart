import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../home/tabs/map/presentation/map_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../home/tabs/map/data/map_repository.dart';
import '../../../home/tabs/home/data/models/map_item_models.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Marker? _pickedMarker;
  String? _selectedAddress;

  String? _lightMapStyle;
  String? _darkMapStyle;

  List<MapItem> _availablePlaces = [];
  bool _isLoadingPlaces = true;

  @override
  void initState() {
    super.initState();
    _zoomToUserLocation();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final repo = sl<MapRepository>();
      final places = await repo.fetchAllMapItemsLimited();
      if (mounted) {
        setState(() {
          _availablePlaces = places;
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlaces = false);
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
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Could not zoom to user location: $e');
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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await _mapController?.setMapStyle(isDark ? _darkMapStyle : _lightMapStyle);
  }

  Future<void> _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _selectedAddress = 'Fetching address...';
      _pickedMarker = Marker(
        markerId: const MarkerId('picked_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          if (place.street?.isNotEmpty == true && place.street != "Unnamed Road" && !place.street!.contains('+')) place.street,
          if (place.subLocality?.isNotEmpty == true && !place.subLocality!.contains('+')) place.subLocality,
          if (place.locality?.isNotEmpty == true && !place.locality!.contains('+')) place.locality,
        ].where((e) => e != null).join(', ');

        setState(() {
          _selectedAddress = address.isNotEmpty ? address : 'Selected Location';
        });
      } else {
        setState(() {
          _selectedAddress = 'Unknown Location';
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: MapConfig.initialPosition,
            markers: _pickedMarker != null ? {_pickedMarker!} : {},
            myLocationEnabled: true,
            // Native button sits at top-right and collides with the search bar —
            // we render a custom FAB at the bottom-right instead.
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
              await _loadAndApplyMapStyleIfNeeded();
            },
            onTap: _onMapTapped,
          ),

          // Custom my-location FAB (bottom-right, above the confirm button when shown)
          Positioned(
            right: 16,
            bottom: _selectedLocation != null ? 200 : 32,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Theme.of(context).colorScheme.surface,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _zoomToUserLocation,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: const Color(0xFFC79A00),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: _isLoadingPlaces 
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Autocomplete<MapItem>(
                    optionsViewBuilder: (context, onSelected, options) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final textColor = isDark ? Colors.white : Colors.black;
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                          child: SizedBox(
                            height: 200,
                            width: MediaQuery.of(context).size.width - 32,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final MapItem option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(option.title, style: TextStyle(color: textColor)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<MapItem>.empty();
                      }
                      return _availablePlaces.where((MapItem option) {
                        return option.title.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (MapItem option) => option.title,
                    onSelected: (MapItem selection) {
                      final target = LatLng(selection.coordinate.latitude, selection.coordinate.longitude);
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: target, zoom: 16),
                        ),
                      );
                      _onMapTapped(target);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: InputDecoration(
                          hintText: 'Search for a landmark or destination...',
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          suffixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      );
                    },
                  ),
            ),
          ),

          if (_selectedLocation == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: const Text(
                  'Tap anywhere on the map to select a location',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),

          if (_selectedLocation != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFC79A00), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedAddress ?? 'Selected Location',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_selectedLocation != null)
            Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'lat': _selectedLocation!.latitude,
                    'lng': _selectedLocation!.longitude,
                    'name': _selectedAddress ?? 'Custom Pin Location', 
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFFC79A00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
