import 'package:flutter/material.dart';

class MapLoadingOverlay extends StatelessWidget {
  final bool isLoading;

  const MapLoadingOverlay({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

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

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg(strong: true),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
                border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primary)),
                  const SizedBox(width: 10),
                  Text("Loading...",
                      style: TextStyle(color: onSurface.withOpacity(0.9))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
