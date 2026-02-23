import 'package:equatable/equatable.dart';
import '../../home/data/models/map_item_models.dart';
import '../models/route_info.dart';

class MapState extends Equatable {
  final bool isLoading;
  final bool isLocationPermissionGranted;
  final String selectedUiCategoryId;
  final List<MapItem> allItems;
  final List<MapItem> allItemsCache;
  final MapItem? selectedPlace;
  final double currentZoom;
  
  // Search
  final List<MapItem> searchResults;
  final bool isSearchActive;

  // Navigation
  final RouteInfo? currentRoute;
  final bool isNavigationMode;
  final bool isLoadingRoute;
  final String selectedTravelMode;
  final MapItem? navigationDestination;
  
  final String? error;

  const MapState({
    this.isLoading = false,
    this.isLocationPermissionGranted = false,
    this.selectedUiCategoryId = 'all',
    this.allItems = const [],
    this.allItemsCache = const [],
    this.selectedPlace,
    this.currentZoom = 10.0,
    this.searchResults = const [],
    this.isSearchActive = false,
    this.currentRoute,
    this.isNavigationMode = false,
    this.isLoadingRoute = false,
    this.selectedTravelMode = 'driving',
    this.navigationDestination,
    this.error,
  });

  MapState copyWith({
    bool? isLoading,
    bool? isLocationPermissionGranted,
    String? selectedUiCategoryId,
    List<MapItem>? allItems,
    List<MapItem>? allItemsCache,
    MapItem? selectedPlace,
    double? currentZoom,
    List<MapItem>? searchResults,
    bool? isSearchActive,
    RouteInfo? currentRoute,
    bool? isNavigationMode,
    bool? isLoadingRoute,
    String? selectedTravelMode,
    MapItem? navigationDestination,
    String? error,
  }) {
    return MapState(
      isLoading: isLoading ?? this.isLoading,
      isLocationPermissionGranted: isLocationPermissionGranted ?? this.isLocationPermissionGranted,
      selectedUiCategoryId: selectedUiCategoryId ?? this.selectedUiCategoryId,
      allItems: allItems ?? this.allItems,
      allItemsCache: allItemsCache ?? this.allItemsCache,
      selectedPlace: selectedPlace, // Handle null properly? It's fine for simple copyWith if we allow clearing by passing null? Wait, standard copyWith doesn't handle null well if we want to clear it. For this codebase, let's keep it simple.
      currentZoom: currentZoom ?? this.currentZoom,
      searchResults: searchResults ?? this.searchResults,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      currentRoute: currentRoute,
      isNavigationMode: isNavigationMode ?? this.isNavigationMode,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      selectedTravelMode: selectedTravelMode ?? this.selectedTravelMode,
      navigationDestination: navigationDestination,
      error: error,
    );
  }

  // Helper method for clearing specific nullable fields
  MapState copyWithClearPlace({
    bool? isLoading,
    bool? isLocationPermissionGranted,
    String? selectedUiCategoryId,
    List<MapItem>? allItems,
    List<MapItem>? allItemsCache,
    double? currentZoom,
    List<MapItem>? searchResults,
    bool? isSearchActive,
    RouteInfo? currentRoute,
    bool? isNavigationMode,
    bool? isLoadingRoute,
    String? selectedTravelMode,
    MapItem? navigationDestination,
    String? error,
  }) {
    return MapState(
      isLoading: isLoading ?? this.isLoading,
      isLocationPermissionGranted: isLocationPermissionGranted ?? this.isLocationPermissionGranted,
      selectedUiCategoryId: selectedUiCategoryId ?? this.selectedUiCategoryId,
      allItems: allItems ?? this.allItems,
      allItemsCache: allItemsCache ?? this.allItemsCache,
      selectedPlace: null,
      currentZoom: currentZoom ?? this.currentZoom,
      searchResults: searchResults ?? this.searchResults,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      currentRoute: currentRoute,
      isNavigationMode: isNavigationMode ?? this.isNavigationMode,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      selectedTravelMode: selectedTravelMode ?? this.selectedTravelMode,
      navigationDestination: navigationDestination,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLocationPermissionGranted,
        selectedUiCategoryId,
        allItems,
        allItemsCache,
        selectedPlace,
        currentZoom,
        searchResults,
        isSearchActive,
        currentRoute,
        isNavigationMode,
        isLoadingRoute,
        selectedTravelMode,
        navigationDestination,
        error,
      ];
}
