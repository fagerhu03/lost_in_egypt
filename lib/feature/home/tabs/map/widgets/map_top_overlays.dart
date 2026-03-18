import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/presentation/map_config.dart';

import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import 'map_filter_sheet.dart';

class MapTopOverlays extends StatelessWidget {
  final MapState state;
  final int visibleMarkersCount;

  const MapTopOverlays({
    super.key,
    required this.state,
    required this.visibleMarkersCount,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isSearchActive || state.isNavigationMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.18);

    Color chipBg({bool strong = false}) =>
        surface.withOpacity(strong ? (isDark ? 0.92 : 0.95) : 0.92);

    return Stack(
      children: [
        // Places Count Chip
        Positioned(
          top: 110,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chipBg(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))
              ],
              border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$visibleMarkersCount/${state.allItems.length} places',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withOpacity(0.9)),
                ),
                if (state.selectedUiCategoryId != 'all')
                  Text(
                    MapConfig.categories
                        .firstWhere((c) => c.id == state.selectedUiCategoryId,
                            orElse: () => const UiCategory('', 'Unknown', ''))
                        .label,
                    style: TextStyle(
                        fontSize: 10,
                        color: primary,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),

        // Filter Button
        Positioned(
          top: 110,
          right: 20,
          child: GestureDetector(
            onTap: () async {
              final chosen = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                backgroundColor: surface,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => MapFilterSheet(
                  selectedCategory: state.selectedUiCategoryId,
                  allItems: state.allItemsCache,
                  onCategorySelected: (category) =>
                      Navigator.pop(context, category),
                ),
              );
              if (chosen != null && context.mounted) {
                context.read<MapBloc>().add(MapCategoryChanged(chosen));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: state.selectedUiCategoryId == 'all'
                    ? chipBg()
                    : primary.withOpacity(isDark ? 0.90 : 0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))
                ],
                border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    color: state.selectedUiCategoryId == 'all'
                        ? onSurface.withOpacity(0.9)
                        : Colors.white,
                    size: 20,
                  ),
                  if (state.selectedUiCategoryId != 'all') ...[
                    const SizedBox(width: 6),
                    Text(
                      MapConfig.categories
                          .firstWhere((c) => c.id == state.selectedUiCategoryId,
                              orElse: () => const UiCategory('', '', ''))
                          .icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
