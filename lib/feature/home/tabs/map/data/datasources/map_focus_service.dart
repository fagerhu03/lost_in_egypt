import 'package:flutter/foundation.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class MapFocusService {
  static final MapFocusService instance = MapFocusService._();
  MapFocusService._();

  final ValueNotifier<MapItem?> focusedItemNotifier = ValueNotifier<MapItem?>(null);
  final ValueNotifier<int> tabSwitchNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<MapItem>?> pendingTripNotifier = ValueNotifier<List<MapItem>?>(null);

  /// View-only route: shows all stop markers + fits camera bounds.
  /// Does NOT auto-request directions.
  final ValueNotifier<List<MapItem>?> viewRouteNotifier = ValueNotifier<List<MapItem>?>(null);

  /// Just pans the camera to a coordinate — no marker selected, no detail sheet.
  final ValueNotifier<MapItem?> cameraOnlyNotifier = ValueNotifier<MapItem?>(null);

  /// Active solo-tour stop — map shows a gold pin + "Back to Tour" button.
  final ValueNotifier<MapItem?> tourStopNotifier = ValueNotifier<MapItem?>(null);

  /// The plan currently being toured. Null when no tour is active.
  SavedPlan? activeTourPlan;

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