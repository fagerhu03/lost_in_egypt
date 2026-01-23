import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
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
  final String icon;
  const _UiCategory(this.id, this.label, this.icon);
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
  List<MapItem> _allItemsCache = []; // Cache for all items
  double _currentZoom = 10.0;

  MapItem? _selectedPlace;

  String? _lightMapStyle;
  String? _darkMapStyle;
  Brightness? _lastBrightness;

  // ═══════════════════════════════════════════════════════════
  // 🎨 CUSTOM MARKER ICONS
  // ═══════════════════════════════════════════════════════════

  Map<String, BitmapDescriptor> _markerIcons = {};
  bool _iconsLoaded = false;

  // Categories to EXCLUDE from the map
  static const Set<String> _excludedCategories = {
    'sports',
    'health',
    'government',
  };

  // Category mapping: data category -> pin file name (without extension)
  static const Map<String, String> _categoryToPinMap = {
    'tourism': 'tourism',
    'historical': 'tourism',
    'museum': 'tourism',
    'hotel': 'hotels',
    'food': 'resturants',
    'nature': 'nature',
    'entertainment': 'entertainment',
    'shopping': 'shopping',
    'transport': 'transport',
    'religious': 'default',
    'education': 'default',
  };

  // Marker size
  static const int _markerSize = 120;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 10,
  );

  // ═══════════════════════════════════════════════════════════
  // 📂 CATEGORIES - Matching your data exactly
  // ═══════════════════════════════════════════════════════════

  static const List<_UiCategory> _categories = [
    _UiCategory('all', 'All', '🗺️'),
    _UiCategory('tourism', 'Tourism', '🏛️'),
    _UiCategory('historical', 'Historical', '🏺'),
    _UiCategory('museum', 'Museums', '🖼️'),
    _UiCategory('hotel', 'Hotels', '🏨'),
    _UiCategory('religious', 'Religious', '🕌'),
    _UiCategory('food', 'Food & Dining', '🍽️'),
    _UiCategory('nature', 'Nature', '🌿'),
    _UiCategory('entertainment', 'Entertainment', '🎭'),
    _UiCategory('education', 'Education', '🎓'),
    _UiCategory('shopping', 'Shopping', '🛍️'),
    _UiCategory('transport', 'Transport', '🚌'),
  ];

  // ═══════════════════════════════════════════════════════════
  // 🎬 LIFECYCLE METHODS
  // ═══════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcons();
    _checkLocationPermission();
    _loadByCategory('all');
    MapFocusService.instance.focusedItemNotifier.addListener(_onFocusRequested);
  }

  @override
  void dispose() {
    MapFocusService.instance.focusedItemNotifier
        .removeListener(_onFocusRequested);
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

  // ═══════════════════════════════════════════════════════════
  // 🎨 CUSTOM PNG MARKER LOADING METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadCustomMarkerIcons() async {
    try {
      final pinNames = [
        'default',
        'entertainment',
        'hotels',
        'nature',
        'resturants',
        'shopping',
        'tourism',
        'transport',
      ];

      for (final pinName in pinNames) {
        try {
          final icon = await _loadPngMarkerIcon(
            'assets/pins/$pinName.png',
            _markerSize,
          );
          _markerIcons[pinName] = icon;
          debugPrint('✅ Loaded marker: $pinName');
        } catch (e) {
          debugPrint('⚠️ Failed to load marker $pinName: $e');
          _markerIcons[pinName] = BitmapDescriptor.defaultMarker;
        }
      }

      _iconsLoaded = true;

      if (_allItems.isNotEmpty && mounted) {
        _updateVisibleMarkers();
      }

      debugPrint('🎨 All custom markers loaded! Total: ${_markerIcons.length}');
    } catch (e) {
      debugPrint('❌ Error loading custom markers: $e');
      _iconsLoaded = true;
    }
  }

  Future<BitmapDescriptor> _loadPngMarkerIcon(String assetPath, int width) async {
    final ByteData data = await rootBundle.load(assetPath);

    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );

    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final ByteData? byteData = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    frameInfo.image.dispose();

    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  BitmapDescriptor _getMarkerIconByCategory(MapItem item, bool isSelected) {
    if (!_iconsLoaded || _markerIcons.isEmpty) {
      return BitmapDescriptor.defaultMarker;
    }

    final category = item.category.toLowerCase();
    final pinName = _categoryToPinMap[category] ?? 'default';

    if (_markerIcons.containsKey(pinName)) {
      return _markerIcons[pinName]!;
    }

    return _markerIcons['default'] ?? BitmapDescriptor.defaultMarker;
  }

  bool _shouldShowItem(MapItem item) {
    return !_excludedCategories.contains(item.category.toLowerCase());
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 MARKER UPDATE METHOD
  // ═══════════════════════════════════════════════════════════

  void _updateVisibleMarkers({MapItem? forceInclude}) {
    if (_allItems.isEmpty && forceInclude == null) {
      setState(() => _markers = {});
      debugPrint('⚠️ No items to display');
      return;
    }

    List<MapItem> filteredItems;

    // Check if specific category is selected
    if (_selectedUiCategoryId == 'all') {
      // "All" selected → Apply zoom-based importance filtering
      filteredItems = MarkerFilterService.filterByZoom(_allItems, _currentZoom);
      debugPrint(
          '🔍 Filter: ALL with zoom filtering (zoom: ${_currentZoom.toStringAsFixed(1)})');
    } else {
      // Specific category selected → NO zoom filtering, show ALL in category
      filteredItems = List.from(_allItems);
      debugPrint(
          '🔍 Filter: Category "$_selectedUiCategoryId" - NO zoom filtering');
    }

    // Filter out excluded categories
    filteredItems = filteredItems.where(_shouldShowItem).toList();

    // Force include selected place if needed
    if (forceInclude != null &&
        !filteredItems.any((p) => p.id == forceInclude.id)) {
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
        icon: _getMarkerIconByCategory(item, isSelected),
        anchor: const Offset(0.5, 1.0),
        onTap: () => _onMarkerTapped(item),
      );
    }).toSet();

    if (mounted) {
      setState(() => _markers = markers);
    }

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
    debugPrint('🎯 _focusOnPlace: ${place.title}');
    debugPrint(
        '   📍 Lat: ${place.coordinate.latitude}, Lng: ${place.coordinate.longitude}');

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
            target:
                LatLng(place.coordinate.latitude, place.coordinate.longitude),
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

  // ═══════════════════════════════════════════════════════════
  // 🎨 MAP STYLE METHODS
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadAndApplyMapStyleIfNeeded() async {
    if (_lightMapStyle == null) {
      _lightMapStyle = await rootBundle.loadString('assets/map_style.json');
    }
    if (_darkMapStyle == null) {
      try {
        _darkMapStyle =
            await rootBundle.loadString('assets/map_style_dark.json');
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
  // 📦 FIXED DATA LOADING METHODS - Load all, filter locally
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadAllItemsIfNeeded() async {
    if (_allItemsCache.isEmpty) {
      debugPrint('📦 Loading all items into cache...');
      _allItemsCache = await _repository.fetchByUiCategory('all', limit: 3000);
      debugPrint('📦 Cached ${_allItemsCache.length} items');
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
    setState(() {
      _loading = true;
      _selectedUiCategoryId = uiCategoryId;
    });

    // Always load all items first (cached after first load)
    await _loadAllItemsIfNeeded();

    List<MapItem> items;

    if (uiCategoryId == 'all') {
      // Show all items (excluding sports, health, government)
      items = _allItemsCache.where(_shouldShowItem).toList();
      debugPrint('📦 Showing ALL categories: ${items.length} items');
    } else {
      // Filter locally by exact category match
      items = _allItemsCache.where((item) {
        final itemCategory = item.category.toLowerCase().trim();
        final filterCategory = uiCategoryId.toLowerCase().trim();
        return itemCategory == filterCategory;
      }).toList();

      debugPrint('📦 Filtered "$uiCategoryId": ${items.length} items');
    }

    _allItems = items;
    _updateVisibleMarkers();

    if (mounted) setState(() => _loading = false);
  }

  // ═══════════════════════════════════════════════════════════
  // 🖱️ INTERACTION METHODS
  // ═══════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════
  // 📂 CATEGORY SHEET
  // ═══════════════════════════════════════════════════════════

  Future<void> _openCategorySheet() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        "Filter by Category",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedUiCategoryId == 'all'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedUiCategoryId == 'all'
                              ? 'Zoom Filter ON'
                              : 'Showing All',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedUiCategoryId == 'all'
                                ? Colors.blue
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Category list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category.id == _selectedUiCategoryId;

                      // Get count for this category from cache
                      final count = category.id == 'all'
                          ? _allItemsCache.where(_shouldShowItem).length
                          : _allItemsCache
                              .where((item) =>
                                  item.category.toLowerCase() ==
                                  category.id.toLowerCase())
                              .length;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              category.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        title: Text(
                          category.label,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          category.id == 'all'
                              ? '$count places • Zoom to see more'
                              : '$count places',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                              )
                            : const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                        onTap: () => Navigator.pop(context, category.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ GOOGLE MAP
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

              final pendingFocus =
                  MapFocusService.instance.focusedItemNotifier.value;
              if (pendingFocus != null) {
                debugPrint(
                    '🎯 Processing pending focus: ${pendingFocus.title}');
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10)
                  ],
                ),
                child: const Text(
                  "Lost In Egypt",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontFamily: "Marcellus"),
                ),
              ),
            ),
          ),

          // 📊 PLACE COUNT & CURRENT FILTER
          Positioned(
            top: 110,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_markers.length}/${_allItems.length} places',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_selectedUiCategoryId != 'all')
                    Text(
                      _categories
                          .firstWhere(
                            (c) => c.id == _selectedUiCategoryId,
                            orElse: () =>
                                const _UiCategory('', 'Unknown', ''),
                          )
                          .label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedUiCategoryId == 'all'
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      color: _selectedUiCategoryId == 'all'
                          ? Colors.black87
                          : Colors.white,
                      size: 20,
                    ),
                    if (_selectedUiCategoryId != 'all') ...[
                      const SizedBox(width: 6),
                      Text(
                        _categories
                            .firstWhere(
                              (c) => c.id == _selectedUiCategoryId,
                              orElse: () => const _UiCategory('', '', ''),
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
                color:
                    _isLocationPermissionGranted ? Colors.blue : Colors.black87,
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
                backgroundColor: Colors.white,
                onPressed: () => _loadByCategory('all'),
                icon: const Icon(Icons.close, color: Colors.black87, size: 18),
                label: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.black87),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
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