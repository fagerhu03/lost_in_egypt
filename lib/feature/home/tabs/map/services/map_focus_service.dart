
import 'package:flutter/foundation.dart';
import '../../../data/models/map_item_models.dart';
import '../../home/data/models/map_item_models.dart';

class MapFocusService {
  static final MapFocusService instance = MapFocusService._();
  MapFocusService._();

  final ValueNotifier<MapItem?> focusedItemNotifier =
  ValueNotifier<MapItem?>(null);

  // 0=Home,1=Community,2=Camera,3=Map,4=More
  final ValueNotifier<int> tabSwitchNotifier = ValueNotifier<int>(0);

  void triggerFocus(MapItem item) {
    debugPrint("🚀 triggerFocus: ${item.title}");
    focusedItemNotifier.value = item;
    tabSwitchNotifier.value = 3; // Map tab index
  }

  void clearFocus() {
    focusedItemNotifier.value = null;
  }

  void switchToTab(int tabIndex) {
    tabSwitchNotifier.value = tabIndex;
  }
}
