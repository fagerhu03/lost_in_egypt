import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class MapFocusService {
  static final MapFocusService instance = MapFocusService._();
  MapFocusService._();

  final ValueNotifier<MapItem?> focusedItemNotifier = ValueNotifier<MapItem?>(null);
  final ValueNotifier<int> tabSwitchNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<MapItem>?> pendingTripNotifier = ValueNotifier<List<MapItem>?>(null);

  /// Currently visible tab index. HomeWrapper writes to this on every tab
  /// change (taps + programmatic + PageView callbacks). MapScreen reads it
  /// to decide whether to bootstrap MapBloc — preventing the Places API
  /// cold-start fetch from firing during home→more transitions that animate
  /// through the map tab.
  final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  /// View-only route: shows all stop markers + fits camera bounds.
  /// Does NOT auto-request directions.
  final ValueNotifier<List<MapItem>?> viewRouteNotifier = ValueNotifier<List<MapItem>?>(null);

  /// Just pans the camera to a coordinate — no marker selected, no detail sheet.
  final ValueNotifier<MapItem?> cameraOnlyNotifier = ValueNotifier<MapItem?>(null);

  /// Active solo-tour stop — map shows a gold pin + "Back to Tour" button.
  final ValueNotifier<MapItem?> tourStopNotifier = ValueNotifier<MapItem?>(null);

  /// The plan currently being toured. Null when no tour is active.
  SavedPlan? activeTourPlan;

  /// One-shot action queued by a notification tap that launched the app from a
  /// terminated state (FCM getInitialMessage). HomeWrapper runs + clears it on
  /// its first frame, once the tab/map infrastructure is live. Null on every
  /// normal launch, so it never affects the default startup path.
  VoidCallback? pendingLaunchAction;

  void triggerFocus(MapItem item) {
    debugPrint("🚀 MapFocusService.triggerFocus: ${item.title}");
    debugPrint("   📍 Coordinates: ${item.coordinate.latitude}, ${item.coordinate.longitude}");
    focusedItemNotifier.value = item;
    // Microtask defers the tab switch until after any pending popUntil completes,
    // preventing the PageView.onPageChanged callback from resetting the index back
    // to 0 during the pop animation.
    Future.microtask(() {
      if (tabSwitchNotifier.value != 2) {
        tabSwitchNotifier.value = 2;
      } else {
        tabSwitchNotifier.value = -1;
        tabSwitchNotifier.value = 2;
      }
    });
  }

  /// Switches to the map tab and pans to [item]'s coordinates without
  /// selecting the place or opening the detail sheet.
  void triggerCameraFocus(MapItem item) {
    debugPrint("📷 MapFocusService.triggerCameraFocus: ${item.title}");
    cameraOnlyNotifier.value = item;
    Future.microtask(() {
      if (tabSwitchNotifier.value != 2) {
        tabSwitchNotifier.value = 2;
      } else {
        tabSwitchNotifier.value = -1;
        tabSwitchNotifier.value = 2;
      }
    });
  }

  void clearCameraFocus() {
    cameraOnlyNotifier.value = null;
  }

  void clearFocus() {
    debugPrint("🧹 MapFocusService.clearFocus");
    focusedItemNotifier.value = null;
  }

  /// Focuses the map on a daily-discovery landmark. Builds a lightweight
  /// synthetic place from the name + coords; the map screen resolves it to the
  /// real dataset pin (photos / reviews / description) when one is within
  /// range, otherwise it still pans to the coordinates and selects the pin.
  void focusDiscovery(String name, double lat, double lng) {
    triggerFocus(PlaceModel(
      id: 'discovery_${name.toLowerCase().replaceAll(' ', '_')}',
      title: name,
      category: 'tourism',
      coordinate: GeoPoint(lat, lng),
      imagePath: '',
      locationAddress: '',
      rating: 0,
      price: 0,
      duration: '',
      weather: '',
      description: '',
    ));
  }

  /// Parses a daily-discovery deep link of the form `name|lat|lng` and
  /// focuses the map on it. Returns false (no-op) when the payload is malformed
  /// — e.g. legacy notifications written before deep-link payloads existed.
  bool focusDiscoveryFromDeepLink(String payload) {
    final parts = payload.split('|');
    if (parts.length != 3) return false;
    final lat = double.tryParse(parts[1]);
    final lng = double.tryParse(parts[2]);
    if (lat == null || lng == null) return false;
    focusDiscovery(parts[0], lat, lng);
    return true;
  }

  void switchToTab(int tabIndex) {
    debugPrint("📱 MapFocusService.switchToTab: $tabIndex");
    tabSwitchNotifier.value = tabIndex;
  }

  /// Trigger trip navigation from a tour — pre-populates the trip planner
  void triggerTrip(List<MapItem> stops) {
    debugPrint("🗺️ MapFocusService.triggerTrip: ${stops.length} stops");
    pendingTripNotifier.value = stops;
    if (tabSwitchNotifier.value != 2) {
      tabSwitchNotifier.value = 2;
    } else {
      tabSwitchNotifier.value = -1;
      tabSwitchNotifier.value = 2;
    }
  }

  void clearPendingTrip() {
    pendingTripNotifier.value = null;
  }

  /// Shows all [stops] on the map and fits camera bounds — no directions.
  void triggerViewRoute(List<MapItem> stops) {
    debugPrint('🗺️ MapFocusService.triggerViewRoute: ${stops.length} stops');
    viewRouteNotifier.value = stops;
    Future.microtask(() {
      if (tabSwitchNotifier.value != 2) {
        tabSwitchNotifier.value = 2;
      } else {
        tabSwitchNotifier.value = -1;
        tabSwitchNotifier.value = 2;
      }
    });
  }

  void clearViewRoute() {
    viewRouteNotifier.value = null;
  }

  /// Switches to the map tab, pans to [stop], and shows a gold tour pin.
  void triggerTourStop(MapItem stop, SavedPlan plan) {
    debugPrint("🏛 MapFocusService.triggerTourStop: ${stop.title}");
    activeTourPlan = plan;
    tourStopNotifier.value = stop;
    Future.microtask(() {
      if (tabSwitchNotifier.value != 2) {
        tabSwitchNotifier.value = 2;
      } else {
        tabSwitchNotifier.value = -1;
        tabSwitchNotifier.value = 2;
      }
    });
  }

  void clearTourStop() {
    tourStopNotifier.value = null;
    activeTourPlan = null;
  }
}