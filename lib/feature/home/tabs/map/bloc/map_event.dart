import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../home/data/models/map_item_models.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class MapInitialized extends MapEvent {}

class MapCategoryChanged extends MapEvent {
  final String categoryId;
  const MapCategoryChanged(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}

class MapSearchQueryChanged extends MapEvent {
  final String query;
  const MapSearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class MapSearchFocusChanged extends MapEvent {
  final bool isFocused;
  const MapSearchFocusChanged(this.isFocused);

  @override
  List<Object> get props => [isFocused];
}

class MapPlaceSelected extends MapEvent {
  final MapItem? place;
  const MapPlaceSelected(this.place);

  @override
  List<Object?> get props => [place];
}

class MapZoomChanged extends MapEvent {
  final double zoom;
  const MapZoomChanged(this.zoom);

  @override
  List<Object> get props => [zoom];
}

class MapDirectionsRequested extends MapEvent {
  final MapItem destination;
  final String apiKey;
  final String mode;

  const MapDirectionsRequested({
    required this.destination,
    required this.apiKey,
    this.mode = 'driving',
  });

  @override
  List<Object> get props => [destination, apiKey, mode];
}

class MapNavigationModeChanged extends MapEvent {
  final String mode;
  final String apiKey;
  const MapNavigationModeChanged(this.mode, this.apiKey);

  @override
  List<Object> get props => [mode, apiKey];
}

class MapNavigationCleared extends MapEvent {}

class MapLocationPermissionUpdated extends MapEvent {
  final bool isGranted;
  const MapLocationPermissionUpdated(this.isGranted);

  @override
  List<Object> get props => [isGranted];
}
