import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/models/route_info.dart';

class NavigationInfoBar extends StatelessWidget {
  final RouteInfo routeInfo;
  final String selectedMode;
  final bool isLoadingRoute;
  final VoidCallback onClose;
  final VoidCallback onStartNavigation;
  final VoidCallback onShowSteps;
  final ValueChanged<String> onModeChanged;

  const NavigationInfoBar({
    super.key,
    required this.routeInfo,
    required this.selectedMode,
    required this.isLoadingRoute,
    required this.onClose,
    required this.onStartNavigation,
    required this.onShowSteps,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── DRAG HANDLE ──────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ─── TRAVEL MODE SELECTOR ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                _buildModeChip(
                  context: context,
                  icon: Icons.directions_car_rounded,
                  label: 'Drive',
                  mode: 'driving',
                  isSelected: selectedMode == 'driving',
                  primary: primary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context: context,
                  icon: Icons.directions_walk_rounded,
                  label: 'Walk',
                  mode: 'walking',
                  isSelected: selectedMode == 'walking',
                  primary: primary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context: context,
                  icon: Icons.directions_transit_rounded,
                  label: 'Transit',
                  mode: 'transit',
                  isSelected: selectedMode == 'transit',
                  primary: primary,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const Spacer(),
                // Close button
                Material(
                  color: onSurface.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: onClose,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.close_rounded,
                        color: onSurface.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── LOADING INDICATOR ────────────────
          if (isLoadingRoute)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Finding route...',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // ─── ROUTE INFO ───────────────────────
          if (!isLoadingRoute)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  // Duration
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeInfo.duration,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        routeInfo.distance,
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Steps button
                  if (routeInfo.steps.isNotEmpty)
                    Material(
                      color: onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: onShowSteps,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.list_alt_rounded,
                                color: onSurface.withValues(alpha: 0.7),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${routeInfo.steps.length} steps',
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ─── START NAVIGATION BUTTON ──────────
          if (!isLoadingRoute)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onStartNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 22),
                  label: const Text(
                    'Start Navigation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String mode,
    required bool isSelected,
    required Color primary,
    required Color onSurface,
    required bool isDark,
  }) {
    return Material(
      color: isSelected
          ? primary.withValues(alpha: isDark ? 0.25 : 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => onModeChanged(mode),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? primary.withValues(alpha: 0.5)
                  : onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primary : onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}