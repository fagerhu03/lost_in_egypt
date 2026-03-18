import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';

class LiveNavigationOverlay extends StatelessWidget {
  final MapState state;
  final VoidCallback onStopNavigation;
  final VoidCallback onRecenter;
  final bool isFollowingUser;

  const LiveNavigationOverlay({
    super.key,
    required this.state,
    required this.onStopNavigation,
    required this.onRecenter,
    required this.isFollowingUser,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isLiveNavigating || state.currentRoute == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.18);

    final currentStep = (state.currentStepIndex < state.currentRoute!.steps.length)
        ? state.currentRoute!.steps[state.currentStepIndex]
        : null;

    return Stack(
      children: [
        // Instruction Bar at the Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: shadowColor, blurRadius: 16, spreadRadius: 1)
                ],
                border: Border.all(color: primary.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current step instruction
                  if (currentStep != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.navigation_rounded,
                              color: primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStep.instruction,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentStep.distance} · ${currentStep.duration}',
                                style: TextStyle(
                                  color: onSurface.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Overall ETA
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded,
                              color: primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${state.currentRoute!.distance} · ${state.currentRoute!.duration} total',
                            style: TextStyle(
                              color: onSurface.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Step progress bar
                    Row(
                      children: [
                        Text(
                          'Step ${state.currentStepIndex + 1}/${state.currentRoute!.steps.length}',
                          style: TextStyle(
                              color: onSurface.withOpacity(0.5), fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (state.currentStepIndex + 1) /
                                state.currentRoute!.steps.length,
                            backgroundColor: onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(primary),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onStopNavigation,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stop_rounded,
                                color: Colors.red, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Re-center Button
        if (!isFollowingUser)
          Positioned(
            bottom: 30,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: primary,
              onPressed: onRecenter,
              child: const Icon(Icons.my_location_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
      ],
    );
  }
}
