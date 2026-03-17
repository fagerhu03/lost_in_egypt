import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/map_repository.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/navigation_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/presentation/map_config.dart';
import '../../home/data/models/map_item_models.dart';

import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepository _mapRepository;
  final NavigationService _navigationService;

  MapBloc({
    required MapRepository mapRepository,
    required NavigationService navigationService,
  })  : _mapRepository = mapRepository,
        _navigationService = navigationService,
        super(const MapState()) {
    on<MapInitialized>(_onMapInitialized);
    on<MapCategoryChanged>(_onMapCategoryChanged);
    on<MapSearchQueryChanged>(_onMapSearchQueryChanged);
    on<MapSearchFocusChanged>(_onMapSearchFocusChanged);
    on<MapPlaceSelected>(_onMapPlaceSelected);
    on<MapZoomChanged>(_onMapZoomChanged);
    on<MapDirectionsRequested>(_onMapDirectionsRequested);
    on<MapNavigationModeChanged>(_onMapNavigationModeChanged);
    on<MapNavigationCleared>(_onMapNavigationCleared);
    on<MapLocationPermissionUpdated>(_onMapLocationPermissionUpdated);
    on<MapErrorCleared>(_onMapErrorCleared);
    on<MapLiveNavigationStarted>(_onLiveNavigationStarted);
    on<MapLiveNavigationStopped>(_onMapLiveNavigationStopped);
    on<MapUserLocationUpdated>(_onMapUserLocationUpdated);
  }

  bool _shouldShowItem(MapItem item) {
    return !MapConfig.excludedCategories.contains(item.category.toLowerCase());
  }

  Future<void> _onMapInitialized(
    MapInitialized event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final items = await _mapRepository.fetchAllMapItemsLimited();
      final filteredItems = items.where(_shouldShowItem).toList();
      debugPrint('🗺️ Loaded ${filteredItems.length} items for map');
      
      emit(state.copyWith(
        isLoading: false,
        allItems: filteredItems,
        allItemsCache: filteredItems,
      ));
    } catch (e) {
      debugPrint('❌ Error loading map items: $e');
      emit(state.copyWith(isLoading: false, error: 'Error loading places: $e'));
    }
  }

  void _onMapCategoryChanged(
    MapCategoryChanged event,
    Emitter<MapState> emit,
  ) {
    List<MapItem> items;
    if (event.categoryId == 'all' || event.categoryId == 'favorites' || event.categoryId == 'open_now') {
      // 'all', 'favorites', and 'open_now' all need the full item list;
      // actual filtering is handled in the UI layer
      items = state.allItemsCache.where(_shouldShowItem).toList();
    } else {
      items = state.allItemsCache.where((item) {
        final itemCategory = item.category.toLowerCase().trim();
        final filterCategory = event.categoryId.toLowerCase().trim();
        return itemCategory == filterCategory && _shouldShowItem(item);
      }).toList();
    }

    emit(state.copyWith(
      selectedUiCategoryId: event.categoryId,
      allItems: items,
    ));
  }

  void _onMapSearchQueryChanged(
    MapSearchQueryChanged event,
    Emitter<MapState> emit,
  ) {
    final query = event.query.toLowerCase().trim();
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: []));
      return;
    }

    final results = state.allItemsCache.where((item) {
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

    emit(state.copyWith(searchResults: results.take(15).toList()));
  }

  void _onMapSearchFocusChanged(
    MapSearchFocusChanged event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(isSearchActive: event.isFocused));
  }

  void _onMapPlaceSelected(
    MapPlaceSelected event,
    Emitter<MapState> emit,
  ) {
    if (event.place == null) {
      emit(state.copyWithClearPlace(
        searchResults: [],
        isSearchActive: false,
      ));
    } else {
      emit(state.copyWith(
        selectedPlace: event.place,
        searchResults: [],
        isSearchActive: false,
      ));
    }
  }

  void _onMapZoomChanged(
    MapZoomChanged event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(currentZoom: event.zoom));
  }

  Future<void> _onMapDirectionsRequested(
    MapDirectionsRequested event,
    Emitter<MapState> emit,
  ) async {
    if (!state.isLocationPermissionGranted) {
      emit(state.copyWith(error: 'Location permission required for directions'));
      return;
    }

    // Set to loading and clear place/search
    emit(state.copyWithClearPlace(
      isNavigationMode: true,
      isLoadingRoute: true,
      navigationDestination: event.destination,
      selectedTravelMode: event.mode,
      searchResults: [],
      isSearchActive: false,
    ));

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final origin = LatLng(position.latitude, position.longitude);
      final destination = LatLng(
        event.destination.coordinate.latitude,
        event.destination.coordinate.longitude,
      );

      final route = await _navigationService.getDirections(
        origin: origin,
        destination: destination,
        apiKey: event.apiKey,
        mode: event.mode,
      );

      if (route == null) {
        emit(state.copyWithClearPlace(
          isLoadingRoute: false,
          isNavigationMode: false,
          error: 'Could not find a route. Please try again.',
        ));
      } else {
        emit(state.copyWith(
          isLoadingRoute: false,
          currentRoute: route,
          selectedPlace: state.selectedPlace,
          navigationDestination: event.destination, 
        ));
      }
    } catch (e) {
      emit(state.copyWithClearPlace(
        isLoadingRoute: false,
        isNavigationMode: false,
        error: 'Navigation error: $e',
      ));
    }
  }

  Future<void> _onMapNavigationModeChanged(
    MapNavigationModeChanged event,
    Emitter<MapState> emit,
  ) async {
    if (state.navigationDestination == null) return;
    if (event.mode == state.selectedTravelMode) return;

    // Trigger direction request with new mode
    add(MapDirectionsRequested(
      destination: state.navigationDestination!,
      apiKey: event.apiKey,
      mode: event.mode,
    ));
  }

  void _onMapNavigationCleared(
    MapNavigationCleared event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWithClearPlace(
      isNavigationMode: false,
      isLoadingRoute: false,
      currentRoute: null,
      selectedTravelMode: 'driving',
      navigationDestination: null,
    ));
  }

  void _onMapLocationPermissionUpdated(
    MapLocationPermissionUpdated event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(isLocationPermissionGranted: event.isGranted));
  }

  void _onMapErrorCleared(
    MapErrorCleared event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onLiveNavigationStarted(
    MapLiveNavigationStarted event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      isLiveNavigating: true,
      currentStepIndex: 0,
    ));
  }

  void _onMapLiveNavigationStopped(
    MapLiveNavigationStopped event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      isLiveNavigating: false,
      currentStepIndex: 0,
      userLocation: null,
    ));
  }

  void _onMapUserLocationUpdated(
    MapUserLocationUpdated event,
    Emitter<MapState> emit,
  ) {
    final userPos = LatLng(event.latitude, event.longitude);
    
    // Check if arrived at destination
    if (state.navigationDestination != null) {
      final destLat = state.navigationDestination!.coordinate.latitude;
      final destLng = state.navigationDestination!.coordinate.longitude;
      final distToDest = Geolocator.distanceBetween(
        event.latitude, event.longitude, destLat, destLng,
      );
      if (distToDest < 50) {
        emit(state.copyWith(
          userLocation: userPos,
          hasArrived: true,
          isLiveNavigating: false,
        ));
        return;
      }
    }

    // Advance step if user is close to the current step's end location
    int stepIndex = state.currentStepIndex;
    if (state.currentRoute != null && state.currentRoute!.steps.isNotEmpty) {
      final steps = state.currentRoute!.steps;
      if (stepIndex < steps.length) {
        final stepEnd = steps[stepIndex].endLocation;
        final dist = Geolocator.distanceBetween(
          event.latitude, event.longitude,
          stepEnd.latitude, stepEnd.longitude,
        );
        // Advance to next step when within 50 meters
        if (dist < 50 && stepIndex < steps.length - 1) {
          stepIndex++;
        }
      }
    }

    emit(state.copyWith(
      userLocation: userPos,
      currentStepIndex: stepIndex,
    ));
  }
}
