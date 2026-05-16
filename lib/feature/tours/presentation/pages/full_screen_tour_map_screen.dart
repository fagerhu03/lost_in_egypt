import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tour_entity.dart';
import '../../../home/tabs/map/data/datasources/map_focus_service.dart';
import '../../../home/tabs/home/data/models/map_item_models.dart';
import '../../../../core/di/service_locator.dart';
import '../../../home/tabs/map/data/places_api_service.dart';

class FullScreenTourMapScreen extends StatefulWidget {
  final TourEntity tour;

  const FullScreenTourMapScreen({super.key, required this.tour});

  @override
  State<FullScreenTourMapScreen> createState() => _FullScreenTourMapScreenState();
}

class _FullScreenTourMapScreenState extends State<FullScreenTourMapScreen> {
  GoogleMapController? _mapController;
  String? _mapStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final styleParams = isDark ? 'assets/darkmode_map_style.json' : 'assets/map_style.json';
      _mapStyle = await rootBundle.loadString(styleParams);
      _mapController?.setMapStyle(_mapStyle);
    } catch (_) {
      // fallback to default
    }
  }

  void _navigateToMainMap() {
    // Create a PlaceModel from the tour's meetup location so the map knows WHERE to focus
    final meetupPlace = PlaceModel(
      id: 'tour_meetup_${widget.tour.id}',
      title: widget.tour.meetingLocationName,
      category: 'tourism',
      coordinate: GeoPoint(widget.tour.meetingLatitude, widget.tour.meetingLongitude),
      imagePath: widget.tour.images.isNotEmpty ? widget.tour.images.first : '',
      locationAddress: widget.tour.meetingLocationName,
      rating: 0,
      price: 0,
      duration: '',
      weather: '',
      description: 'Tour meetup point for: ${widget.tour.title}',
    );

    // Pop back to root then trigger map focus (which also switches to Map tab index 2)
    Navigator.of(context).popUntil((route) => route.isFirst);
    MapFocusService.instance.triggerFocus(meetupPlace);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Meetup Location',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Marcellus',
          ),
        ),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        toolbarHeight: 60,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.tour.meetingLatitude, widget.tour.meetingLongitude),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('meeting_point'),
                position: LatLng(widget.tour.meetingLatitude, widget.tour.meetingLongitude),
                infoWindow: InfoWindow(title: widget.tour.meetingLocationName, snippet: 'Tour Start Point'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_mapStyle != null) {
                _mapController!.setMapStyle(_mapStyle);
              }
            },
          ),
          
          // Custom zoom controls
          Positioned(
            right: 16,
            top: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: theme.colorScheme.surface,
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  child: Icon(Icons.add, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: theme.colorScheme.surface,
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  child: Icon(Icons.remove, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),

          // Bottom Info Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meeting Point',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.tour.meetingLocationName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Text(
                    'Destinations You Will Visit:',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.tour.destinations.map((dest) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(dest, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Two action buttons: Explore + Navigate Route
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _navigateToMainMap,
                      icon: const Icon(Icons.explore),
                      label: const Text('Explore in Main Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _navigateAsTripRoute,
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Navigate Tour Route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateAsTripRoute() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final stops = <MapItem>[];

      stops.add(PlaceModel(
        id: 'tour_meetup_${widget.tour.id}',
        title: '📍 Meetup: ${widget.tour.meetingLocationName}',
        category: 'meetup',
        coordinate: GeoPoint(widget.tour.meetingLatitude, widget.tour.meetingLongitude),
        imagePath: widget.tour.images.isNotEmpty ? widget.tour.images.first : '',
        locationAddress: widget.tour.meetingLocationName,
        rating: 0,
        price: 0,
        duration: '',
        weather: '',
        description: 'Tour meetup point',
      ));

      final placesApi = sl<PlacesApiService>();

      for (int i = 0; i < widget.tour.destinations.length; i++) {
        final destName = widget.tour.destinations[i];
        
        final results = await placesApi.textSearch(query: "$destName Egypt", maxResultCount: 1);
        
        GeoPoint coord = GeoPoint(
          widget.tour.meetingLatitude + (i + 1) * 0.001,
          widget.tour.meetingLongitude + (i + 1) * 0.001,
        );

        if (results.isNotEmpty) {
           final loc = results.first['location'];
           if (loc != null) {
             coord = GeoPoint(loc['latitude'] as double, loc['longitude'] as double);
           }
        }

        stops.add(PlaceModel(
          id: 'tour_dest_${widget.tour.id}_$i',
          title: destName,
          category: 'tourism',
          coordinate: coord,
          imagePath: '',
          locationAddress: destName,
          rating: 0,
          price: 0,
          duration: '',
          weather: '',
          description: 'Tour destination ${i + 1}',
        ));
      }

      if (mounted) Navigator.pop(context);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      MapFocusService.instance.triggerTrip(stops);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }
}
