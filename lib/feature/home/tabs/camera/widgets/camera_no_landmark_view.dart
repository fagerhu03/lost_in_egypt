import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../presentation/bloc/camera_cubit.dart';
import '../presentation/bloc/camera_state.dart';

class CameraNoLandmarkView extends StatelessWidget {
  final CameraNoLandmarkFound state;
  final CameraController? controller;
  final CameraCubit cubit;

  const CameraNoLandmarkView({
    super.key,
    required this.state,
    this.controller,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (controller != null && controller!.value.isInitialized)
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: CameraPreview(controller!),
            ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    color: Theme.of(context).colorScheme.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.identifiedLabel != null
                        ? 'We found "${state.identifiedLabel}" but it\'s not in our database'
                        : 'Could not identify any landmark',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => cubit.resetToReady(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
