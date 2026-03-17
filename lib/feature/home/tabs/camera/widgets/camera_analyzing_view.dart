import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../presentation/bloc/camera_state.dart';

class CameraAnalyzingView extends StatelessWidget {
  final CameraAnalyzing state;
  final CameraController? controller;

  const CameraAnalyzingView({
    super.key,
    required this.state,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (state.isGalleryImage)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFE6A44A)),
            )
          else if (controller != null && controller!.value.isInitialized)
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
                  CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing image...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                    ),
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
