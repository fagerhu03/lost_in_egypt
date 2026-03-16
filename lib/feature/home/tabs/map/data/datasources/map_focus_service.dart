import 'package:flutter/foundation.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class MapFocusService {
  static final MapFocusService instance = MapFocusService._();
  MapFocusService._();

  final ValueNotifier<MapItem?> focusedItemNotifier = ValueNotifier<MapItem?>(null);
  final ValueNotifier<int> tabSwitchNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<MapItem>?> pendingTripNotifier = ValueNotifier<List<MapItem>?>(null);

  void triggerFocus(MapItem item) {
    debugPrint("🚀 MapFocusService.triggerFocus: ${item.title}");
    debugPrint("   📍 Coordinates: ${item.coordinate.latitude}, ${item.coordinate.longitude}");
    focusedItemNotifier.value = item;
    // Reset to -1 first so ValueNotifier always fires even if already on tab 2
    tabSwitchNotifier.value = -1;
    Future.delayed(const Duration(milliseconds: 300), () {
      tabSwitchNotifier.value = 2;
    });
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
    // Reset to -1 first so ValueNotifier always fires even if already on tab 2
    tabSwitchNotifier.value = -1;
    Future.delayed(const Duration(milliseconds: 300), () {
      tabSwitchNotifier.value = 2;
    });
  }

  void clearPendingTrip() {
    pendingTripNotifier.value = null;
  }
}