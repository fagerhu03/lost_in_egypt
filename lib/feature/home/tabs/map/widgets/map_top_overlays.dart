import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);

    Color chipBg({bool strong = false}) =>
        surface.withValues(alpha: strong ? (isDark ? 0.92 : 0.95) : 0.92);

    return Stack(
      children: [
        // Places Count Chip
        PositionedDirectional(
          top: 110.h,
          start: 20.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: chipBg(),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                    color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))
              ],
              border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.mapPlacesCount(visibleMarkersCount, state.allItems.length),
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withValues(alpha: 0.9)),
                ),
                if (state.selectedUiCategoryId != 'all')
                  Text(
                    mapCategoryLabel(
                        l10n,
                        MapConfig.categories.firstWhere(
                            (c) => c.id == state.selectedUiCategoryId,
                            orElse: () => const UiCategory('', 'Unknown', ''))),
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: primary,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),

        // Filter Button
        PositionedDirectional(
          top: 110.h,
          end: 20.w,
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
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: state.selectedUiCategoryId == 'all'
                    ? chipBg()
                    : primary.withValues(alpha: isDark ? 0.90 : 0.95),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))
                ],
                border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    color: state.selectedUiCategoryId == 'all'
                        ? onSurface.withValues(alpha: 0.9)
                        : Colors.white,
                    size: 20.r,
                  ),
                  if (state.selectedUiCategoryId != 'all') ...[
                    SizedBox(width: 6.w),
                    Text(
                      MapConfig.categories
                          .firstWhere((c) => c.id == state.selectedUiCategoryId,
                              orElse: () => const UiCategory('', '', ''))
                          .icon,
                      style: TextStyle(fontSize: 16.sp),
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
