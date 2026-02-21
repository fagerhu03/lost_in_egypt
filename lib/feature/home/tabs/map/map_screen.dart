import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './data/map_repository.dart';
import '../home/data/models/map_item_models.dart';
import './services/marker_filter_service.dart';
import './services/map_focus_service.dart';
import './services/map_marker_service.dart';
import './services/navigation_service.dart';
import './models/route_info.dart';
import './place_detail_screen.dart';
import './map_config.dart';
import './widgets/map_filter_sheet.dart';
import './widgets/navigation_info_bar.dart';
import './widgets/route_steps_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ─── READ API KEY FROM .env FILE ──────────
  static String get _directionsApiKey =>
      dotenv.env['GOOGLE_CLOUD_VISION_API_KEY'] ?? '';

  final MapRepository _repository = MapRepository();
  final MapMarkerService _markerService = MapMarkerService();
  final NavigationService _navigationService = NavigationService();

  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLocationPermissionGranted = false;
  bool _loading = false;

  String _selectedUiCategoryId = 'all';

  List<MapItem> _allItems = [];
  List<MapItem> _allItemsCache = [];
  double _currentZoom = 10.0;

  MapItem? _selectedPlace;

  // ─────────────────────────────────────────────
  // 🧭 Navigation state
  // ─────────────────────────────────────────────
  RouteInfo? _currentRoute;
  bool _isNavigationMode = false;
  bool _isLoadingRoute = false;
  String _selectedTravelMode = 'driving';
  MapItem? _navigationDestination;

  // ─────────────────────────────────────────────
  // 🔎 Search
  // ─────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<MapItem> _searchResults = [];
  bool _isSearchActive = false;

  // ─────────────────────────────────────────────
  // Map styles (Light / Dark)
  // ─────────────────────────────────────────────
  String? _lightMapStyle;
  String? _darkMapStyle;
  Brightness? _lastBrightness;

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initializeMap();

    _searchController.addListener(_onSearchChanged);

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchActive = _searchFocusNode.hasFocus;
        });
      }
    });
  }

  Future<void> _initializeMap() async {
    await _markerService.loadCustomMarkerIcons();
    await _checkLocationPermission();
    await _loadByCategory('all');

    MapFocusService.instance.focusedItemNotifier.addListener(_onFocusRequested);

    // Debug: verify the API key is loaded
    debugPrint('🔑 Directions API key loaded: ${_directionsApiKey.isNotEmpty ? "YES (${_directionsApiKey.substring(0, 8)}...)" : "❌ MISSING"}');
  }

  @override
  void dispose() {
    MapFocusService.instance.focusedItemNotifier
        .removeListener(_onFocusRequested);
    _searchController.removeListener(_onSearchChanged);
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

  bool _shouldShowItem(MapItem item) {
    return !MapConfig.excludedCategories.contains(item.category.toLowerCase());
  }

  // ═══════════════════════════════════════════════════════════
  // 📐 CAMERA OFFSET HELPER
  // ═══════════════════════════════════════════════════════════

  LatLng _offsetTargetForSheet(double lat, double lng, double zoom) {
    const double sheetFraction = 0.55;
    final double degreesVisible = 170.0 / pow(2, zoom);
    final double latOffset = degreesVisible * sheetFraction * 0.5;
    return LatLng(lat - latOffset, lng);
  }

  // ═══════════════════════════════════════════════════════════
  // 🧭 NAVIGATION / DIRECTIONS METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _requestDirections() async {
    if (_selectedPlace == null) return;

    // Check API key
    if (_directionsApiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key not found. Check your .env file.'),
          ),
        );
      }
      return;
    }

    if (!_isLocationPermissionGranted) {
      await _checkLocationPermission();
      if (!_isLocationPermissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission required for directions'),
            ),
          );
        }
        return;
      }
    }

    // Save destination and enter navigation mode
    _navigationDestination = _selectedPlace;

    if (mounted) {
      setState(() {
        _isNavigationMode = true;
        _isLoadingRoute = true;
        _selectedPlace = null; // close detail sheet
      });
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = LatLng(position.latitude, position.longitude);
      final destination = LatLng(
        _navigationDestination!.coordinate.latitude,
        _navigationDestination!.coordinate.longitude,
      );

      final route = await _navigationService.getDirections(
        origin: origin,
        destination: destination,
        apiKey: _directionsApiKey,
        mode: _selectedTravelMode,
      );

      if (route == null) {
        if (mounted) {
          setState(() {
            _isLoadingRoute = false;
            _isNavigationMode = false;
            _navigationDestination = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find a route. Please try again.'),
            ),
          );
        }
        return;
      }

      _applyRoute(route);
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          _isNavigationMode = false;
          _navigationDestination = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation error: $e')),
        );
      }
    }
  }

  Future<void> _changeTravelMode(String mode) async {
    if (mode == _selectedTravelMode) return;
    if (_navigationDestination == null) return;

    setState(() {
      _selectedTravelMode = mode;
      _isLoadingRoute = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = LatLng(position.latitude, position.longitude);
      final destination = LatLng(
        _navigationDestination!.coordinate.latitude,
        _navigationDestination!.coordinate.longitude,
      );

      final route = await _navigationService.getDirections(
        origin: origin,
        destination: destination,
        apiKey: _directionsApiKey,
        mode: mode,
      );

      if (route == null) {
        if (mounted) {
          setState(() => _isLoadingRoute = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No $mode route found. Try a different mode.'),
            ),
          );
        }
        return;
      }

      _applyRoute(route);
    } catch (e) {
      debugPrint('❌ Travel mode change error: $e');
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _applyRoute(RouteInfo route) {
    final polyline = Polyline(
      polylineId: const PolylineId('navigation_route'),
      points: route.polylinePoints,
      color: Theme.of(context).colorScheme.primary,
      width: 5,
      patterns: _selectedTravelMode == 'walking'
          ? [PatternItem.dot, PatternItem.gap(10)]
          : [],
    );

    if (mounted) {
      setState(() {
        _currentRoute = route;
        _polylines = {polyline};
        _isLoadingRoute = false;
      });
    }

    _fitRouteBounds(route.bounds);
  }

  void _fitRouteBounds(LatLngBounds bounds) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void _clearNavigation() {
    if (mounted) {
      setState(() {
        _isNavigationMode = false;
        _currentRoute = null;
        _polylines = {};
        _isLoadingRoute = false;
        _selectedTravelMode = 'driving';
        _navigationDestination = null;
      });
    }
  }

  Future<void> _openGoogleMapsNavigation() async {
    if (_navigationDestination == null) return;

    final destLat = _navigationDestination!.coordinate.latitude;
    final destLng = _navigationDestination!.coordinate.longitude;

    final mode = _selectedTravelMode == 'driving'
        ? 'd'
        : _selectedTravelMode == 'walking'
            ? 'w'
            : 'r'; // r = transit

    final url = Uri.parse(
      'google.navigation:q=$destLat,$destLng&mode=$mode',
    );

    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destLat,$destLng'
      '&travelmode=$_selectedTravelMode',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Launch error: $e');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showRouteSteps() {
    if (_currentRoute == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RouteStepsSheet(routeInfo: _currentRoute!),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔎 SEARCH METHODS
  // ═══════════════════════════════════════════════════════════

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    final results = _allItemsCache.where((item) {
      final title = item.title.toLowerCase();
      final category = item.category.toLowerCase();
      return title.contains(query) || category.contains(query);
    }).toList();

    results.sort((a, b) {
      final aStartsWith = a.title.toLowerCase().startsWith(query) ? 0 : 1;
      final bStartsWith = b.title.toLowerCase().startsWith(query) ? 0 : 1;
      if (aStartsWith != bStartsWith) return aStartsWith - bStartsWith;
      return a.title.compareTo(b.title);
    });

    if (mounted) {
      setState(() {
        _searchResults = results.take(15).toList();
      });
    }
  }

  void _onSearchResultTapped(MapItem item) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (mounted) {
      setState(() {
        _searchResults = [];
        _isSearchActive = false;
      });
    }

    if (_isNavigationMode) _clearNavigation();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _focusOnPlace(item);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (mounted) {
      setState(() {
        _searchResults = [];
        _isSearchActive = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 MARKER UPDATE METHOD
  // ═══════════════════════════════════════════════════════════

  void _updateVisibleMarkers({MapItem? forceInclude}) {
    if (_allItems.isEmpty && forceInclude == null) {
      if (mounted) setState(() => _markers = {});
      return;
    }

    List<MapItem> filteredItems;

    if (_selectedUiCategoryId == 'all') {
      filteredItems = MarkerFilterService.filterByZoom(_allItems, _currentZoom);
    } else {
      filteredItems = List.from(_allItems);
    }

    filteredItems = filteredItems.where(_shouldShowItem).toList();

    if (forceInclude != null &&
        !filteredItems.any((p) => p.id == forceInclude.id)) {
      if (_shouldShowItem(forceInclude)) {
        filteredItems = [...filteredItems, forceInclude];
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
  }

  // ═══════════════════════════════════════════════════════════
  // 📍 FOCUS & NAVIGATION METHODS
  // ═══════════════════════════════════════════════════════════

  void _onFocusRequested() {
    final item = MapFocusService.instance.focusedItemNotifier.value;
    if (item != null && mounted) {
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

    const double targetZoom = 17;

    final offsetTarget = _offsetTargetForSheet(
      place.coordinate.latitude,
      place.coordinate.longitude,
      targetZoom,
    );

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: offsetTarget,
            zoom: targetZoom,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Camera animation error: $e');
    }

    _currentZoom = targetZoom;
    _updateVisibleMarkers(forceInclude: place);
    MapFocusService.instance.clearFocus();
  }

  // ═══════════════════════════════════════════════════════════
  // 🎨 MAP STYLE METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadAndApplyMapStyleIfNeeded() async {
    _lightMapStyle ??= await rootBundle.loadString('assets/map_style.json');

    if (_darkMapStyle == null) {
      try {
        _darkMapStyle =
            await rootBundle.loadString('assets/darkmode_map_style.json');
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
      _allItemsCache =
          await _repository.fetchByUiCategory('all', limit: 3000);
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
    if (_isSearchActive) _clearSearch();
    if (_isNavigationMode) _clearNavigation();

    if (mounted) setState(() => _selectedPlace = place);

    const double targetZoom = 17;
    final offsetTarget = _offsetTargetForSheet(
      place.coordinate.latitude,
      place.coordinate.longitude,
      targetZoom,
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: offsetTarget,
          zoom: targetZoom,
        ),
      ),
    );

    _updateVisibleMarkers(forceInclude: place);
  }

  void _closeDetailSheet() {
    if (mounted) setState(() => _selectedPlace = null);
    _updateVisibleMarkers();
  }

  Future<void> _openCategorySheet() async {
    if (_isSearchActive) _clearSearch();

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
  // 🔎 SEARCH BAR WIDGET
  // ═══════════════════════════════════════════════════════════

  Widget _buildSearchBar({
    required Color surface,
    required Color onSurface,
    required Color primary,
    required Color shadowColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface.withOpacity(isDark ? 0.92 : 0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: onSurface.withOpacity(0.5),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(
                color: onSurface,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search places...',
                hintStyle: TextStyle(
                  color: onSurface.withOpacity(0.4),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.close_rounded,
                  color: onSurface.withOpacity(0.5),
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔎 SEARCH RESULTS WIDGET
  // ═══════════════════════════════════════════════════════════

  Widget _buildSearchResults({
    required Color surface,
    required Color onSurface,
    required Color primary,
    required Color shadowColor,
    required bool isDark,
  }) {
    if (_searchResults.isEmpty && _searchController.text.trim().isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface.withOpacity(isDark ? 0.94 : 0.98),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: onSurface.withOpacity(0.4),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'No places found',
              style: TextStyle(
                color: onSurface.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: surface.withOpacity(isDark ? 0.94 : 0.98),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: onSurface.withOpacity(0.07),
          ),
          itemBuilder: (context, index) {
            final item = _searchResults[index];

            String categoryIcon = '📍';
            try {
              final cat = MapConfig.categories.firstWhere(
                (c) => c.id.toLowerCase() == item.category.toLowerCase(),
              );
              categoryIcon = cat.icon;
            } catch (_) {}

            return InkWell(
              onTap: () => _onSearchResultTapped(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        categoryIcon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.category.toUpperCase(),
                            style: TextStyle(
                              color: primary.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: onSurface.withOpacity(0.25),
                      size: 14,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
      final base =
          surface.withOpacity(strong ? (isDark ? 0.92 : 0.95) : 0.92);
      return base;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ─── LAYER 1: 🗺️ GOOGLE MAP ─────────────────
          GoogleMap(
            initialCameraPosition: MapConfig.initialPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: _isLocationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
              await _loadAndApplyMapStyleIfNeeded();

              final pendingFocus =
                  MapFocusService.instance.focusedItemNotifier.value;
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
              if (_isSearchActive) _clearSearch();
              if (_selectedPlace != null) _closeDetailSheet();
            },
          ),

          // ─── LAYER 2: 📊 PLACE COUNT & CURRENT FILTER ─
          if (!_isSearchActive && !_isNavigationMode)
            Positioned(
              top: 110,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.08),
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
                              orElse: () =>
                                  const UiCategory('', 'Unknown', ''),
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

          // ─── LAYER 3: 🔧 FILTER BUTTON ──────────────
          if (!_isSearchActive && !_isNavigationMode)
            Positioned(
              top: 110,
              right: 20,
              child: GestureDetector(
                onTap: _openCategorySheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
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
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.08),
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
                                orElse: () =>
                                    const UiCategory('', '', ''),
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

          // ─── LAYER 4: 📍 MY LOCATION BUTTON ─────────
          if (!_isSearchActive)
            Positioned(
              bottom: _selectedPlace != null
                  ? 350
                  : _isNavigationMode
                      ? 280
                      : 110,
              right: 20,
              child: FloatingActionButton(
                heroTag: "location_btn",
                backgroundColor:
                    surface.withOpacity(isDark ? 0.92 : 0.95),
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

          // ─── LAYER 5: 🔄 RESET FILTER BUTTON ────────
          if (_selectedUiCategoryId != 'all' &&
              !_isSearchActive &&
              !_isNavigationMode)
            Positioned(
              bottom: _selectedPlace != null ? 350 : 110,
              left: 20,
              child: FloatingActionButton.extended(
                heroTag: "reset_filter_btn",
                backgroundColor:
                    surface.withOpacity(isDark ? 0.92 : 0.95),
                onPressed: () => _loadByCategory('all'),
                icon: Icon(Icons.close,
                    color: onSurface.withOpacity(0.9), size: 18),
                label: Text(
                  'Reset',
                  style: TextStyle(color: onSurface.withOpacity(0.9)),
                ),
              ),
            ),

          // ─── LAYER 6: 📋 PLACE DETAIL SHEET ─────────
          if (_selectedPlace != null && !_isNavigationMode)
            PlaceDetailSheet(
              place: _selectedPlace!,
              onClose: _closeDetailSheet,
              onShowOnMap: () {
                final offsetTarget = _offsetTargetForSheet(
                  _selectedPlace!.coordinate.latitude,
                  _selectedPlace!.coordinate.longitude,
                  _currentZoom,
                );
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: offsetTarget,
                      zoom: _currentZoom,
                    ),
                  ),
                );
              },
              onDirections: _requestDirections,
            ),

          // ─── LAYER 7: 🧭 NAVIGATION INFO BAR ───────
          if (_isNavigationMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _currentRoute != null
                  ? NavigationInfoBar(
                      routeInfo: _currentRoute!,
                      selectedMode: _selectedTravelMode,
                      isLoadingRoute: _isLoadingRoute,
                      onClose: _clearNavigation,
                      onStartNavigation: _openGoogleMapsNavigation,
                      onShowSteps: _showRouteSteps,
                      onModeChanged: _changeTravelMode,
                    )
                  : _isLoadingRoute
                      ? Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, -4),
                              ),
                            ],
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Finding route...',
                                style: TextStyle(
                                  color: onSurface.withOpacity(0.7),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _clearNavigation,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: onSurface.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: onSurface.withOpacity(0.6),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
            ),

          // ─── LAYER 8: ⏳ LOADING INDICATOR ──────────
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.08),
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
                            style: TextStyle(
                                color: onSurface.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ─── LAYER 9: 🔲 SEARCH SCRIM ───────────────
          if (_isSearchActive)
            Positioned.fill(
              child: GestureDetector(
                onTap: _clearSearch,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                ),
              ),
            ),

          // ─── LAYER 10: 🔎 SEARCH BAR + RESULTS ─────
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(
                  surface: surface,
                  onSurface: onSurface,
                  primary: primary,
                  shadowColor: shadowColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                if (_isSearchActive ||
                    _searchController.text.trim().isNotEmpty)
                  _buildSearchResults(
                    surface: surface,
                    onSurface: onSurface,
                    primary: primary,
                    shadowColor: shadowColor,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}