import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lost_in_egypt/l10n/app_localizations.dart';
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

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onMapTapped(LatLng location) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _selectedLocation = location;
      _selectedAddress = l10n.mapPickerFetching;
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
          _selectedAddress = address.isNotEmpty ? address : l10n.mapPickerSelectedLocation;
        });
      } else {
        setState(() {
          _selectedAddress = l10n.mapPickerUnknownLocation;
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
            style: Theme.of(context).brightness == Brightness.dark ? _darkMapStyle : _lightMapStyle,
            onMapCreated: (controller) async {
              _mapController = controller;
              await _loadAndApplyMapStyleIfNeeded();
            },
            onTap: _onMapTapped,
          ),

          // Custom my-location FAB (bottom-right, above the confirm button when shown)
          PositionedDirectional(
            end: 16.w,
            bottom: _selectedLocation != null ? 200.h : 32.h,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Theme.of(context).colorScheme.surface,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _zoomToUserLocation,
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: const Color(0xFFC79A00),
                    size: 22.r,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16.h,
            left: 16.w,
            right: 16.w,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: _isLoadingPlaces
                ? Padding(
                    padding: EdgeInsets.all(16.r),
                    child: const Center(child: CircularProgressIndicator()),
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
                            borderRadius: BorderRadius.circular(8.r),
                            side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                          child: SizedBox(
                            height: 200.h,
                            width: MediaQuery.of(context).size.width - 32.w,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final MapItem option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.r),
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
                          hintText: AppLocalizations.of(context).mapPickerSearchHint,
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          suffixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                      );
                    },
                  ),
            ),
          ),

          if (_selectedLocation == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 90.h,
              left: 16.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Text(
                  AppLocalizations.of(context).mapPickerTapHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),

          if (_selectedLocation != null)
            Positioned(
              bottom: 100.h,
              left: 16.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: const Color(0xFFC79A00), size: 32.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedAddress ?? AppLocalizations.of(context).mapPickerSelectedLocation,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12.sp),
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
              bottom: 32.h,
              left: 32.w,
              right: 32.w,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'lat': _selectedLocation!.latitude,
                    'lng': _selectedLocation!.longitude,
                    'name': _selectedAddress ?? AppLocalizations.of(context).mapPickerCustomPin,
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  backgroundColor: const Color(0xFFC79A00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  elevation: 6,
                ),
                child: Text(
                  AppLocalizations.of(context).mapPickerConfirm,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
