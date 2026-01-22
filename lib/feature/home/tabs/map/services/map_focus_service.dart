import 'package:flutter/foundation.dart';
import '../../home/data/models/map_item_models.dart';

class MapFocusService {
  static final MapFocusService instance = MapFocusService._();
  MapFocusService._();

  final ValueNotifier<MapItem?> focusedItemNotifier = ValueNotifier<MapItem?>(null);
  final ValueNotifier<int> tabSwitchNotifier = ValueNotifier<int>(0);

  void triggerFocus(MapItem item) {
    debugPrint("🚀 MapFocusService.triggerFocus: ${item.title}");
    debugPrint("   📍 Coordinates: ${item.coordinate.latitude}, ${item.coordinate.longitude}");
    focusedItemNotifier.value = item;
    tabSwitchNotifier.value = 3;
  }

  void clearFocus() {
    debugPrint("🧹 MapFocusService.clearFocus");
    focusedItemNotifier.value = null;
  }

  void switchToTab(int tabIndex) {
    debugPrint("📱 MapFocusService.switchToTab: $tabIndex");
    tabSwitchNotifier.value = tabIndex;
  }
}