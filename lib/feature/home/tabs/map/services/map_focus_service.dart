import 'package:flutter/foundation.dart';
import '../../home/data/models/map_item_models.dart';

class MapFocusService {
  // Singleton pattern
  static final MapFocusService instance = MapFocusService._();
  MapFocusService._();

  // Notifier for the item to focus on (used by MapScreen)
  final ValueNotifier<MapItem?> focusedItemNotifier = ValueNotifier(null);
  
  // Notifier for tab switching (used by HomeWrapper)
  final ValueNotifier<int?> tabSwitchNotifier = ValueNotifier(null);

  /// Triggers focus on a specific map item and switches to the Map tab
  void triggerFocus(MapItem item) {
    debugPrint("🚀 SERVICE STEP 1: triggerFocus called for '${item.title}'");
    
    // First, set the focused item so MapScreen knows what to focus on
    focusedItemNotifier.value = item;
    debugPrint("🚀 SERVICE STEP 2: focusedItemNotifier updated");
    
    // Then, trigger the tab switch to Map (index 3)
    debugPrint("🚀 SERVICE STEP 3: Requesting switch to Tab 3 (Map)");
    tabSwitchNotifier.value = 3;
  }

  /// Clears the focus (used when user taps elsewhere or closes the sheet)
  void clearFocus() {
    debugPrint("🚀 SERVICE: Clearing focus");
    focusedItemNotifier.value = null;
    // Don't clear tabSwitchNotifier here - let HomeWrapper handle it
  }

  /// Switch to a specific tab without focusing on any item
  void switchToTab(int tabIndex) {
    debugPrint("🚀 SERVICE: Switching to Tab $tabIndex");
    tabSwitchNotifier.value = tabIndex;
  }
}