import 'dart:io';
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
    // Show captured still image if available (avoids camera freeze effect)
    final capturedPath = state.capturedImagePath;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (capturedPath != null)
            // Show the captured frame as a still background
            Image.file(
              File(capturedPath),
              fit: BoxFit.cover,
            )
          else if (state.isGalleryImage)
            const SizedBox.shrink()
          else if (controller != null && controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: CameraPreview(controller!),
            ),
          // Dark overlay + spinner
          Container(color: Colors.black.withOpacity(capturedPath != null ? 0.55 : 0.0)),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE6A44A)),
                  SizedBox(height: 16),
                  Text(
                    'Identifying landmark…',
                    style: TextStyle(
                      color: Colors.white,
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
