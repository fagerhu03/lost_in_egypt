import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';

class MapActionButtons extends StatelessWidget {
  final MapState state;
  final VoidCallback onGoToUserLocation;

  const MapActionButtons({
    super.key,
    required this.state,
    required this.onGoToUserLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isSearchActive) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    Color chipBg() => surface.withValues(alpha: isDark ? 0.92 : 0.92);

    return Stack(
      children: [
        // My Location FAB
        if (!state.isNavigationMode)
          Positioned(
            bottom: state.selectedPlace != null ? 350.h : 110.h,
            right: 20.w,
            child: FloatingActionButton(
              heroTag: "location_btn",
              backgroundColor: chipBg(),
              onPressed: onGoToUserLocation,
              child: Icon(
                Icons.my_location,
                color: state.isLocationPermissionGranted
                    ? primary
                    : onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
        if (state.isNavigationMode)
          Positioned(
            bottom: 280.h,
            right: 20.w,
            child: FloatingActionButton(
              heroTag: "location_btn",
              backgroundColor: chipBg(),
              onPressed: onGoToUserLocation,
              child: Icon(
                Icons.my_location,
                color: state.isLocationPermissionGranted
                    ? primary
                    : onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),

        // Reset Filter FAB
        if (state.selectedUiCategoryId != 'all' && !state.isNavigationMode)
          Positioned(
            bottom: state.selectedPlace != null ? 350.h : 110.h,
            left: 20.w,
            child: FloatingActionButton.extended(
              heroTag: "reset_filter_btn",
              backgroundColor: chipBg(),
              onPressed: () =>
                  context.read<MapBloc>().add(const MapCategoryChanged('all')),
              icon: Icon(Icons.close,
                  color: onSurface.withValues(alpha: 0.9), size: 18.r),
              label: Text('Reset',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.9))),
            ),
          ),
      ],
    );
  }
}
