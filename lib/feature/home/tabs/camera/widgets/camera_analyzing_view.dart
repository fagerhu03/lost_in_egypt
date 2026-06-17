import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../presentation/bloc/camera_state.dart';

class CameraAnalyzingView extends StatelessWidget {
  final CameraAnalyzing state;
  final CameraController? controller;

  const CameraAnalyzingView({
    super.key,
    required this.state,
    this.controller,
  });

  String _statusLabel(AppLocalizations l10n) {
    switch (state.status) {
      case CameraStatus.capturing:
        return l10n.cameraStatusCapturing;
      case CameraStatus.identifying:
        return l10n.cameraStatusIdentifying;
      case CameraStatus.translating:
        return l10n.cameraStatusTranslating;
      case CameraStatus.downloadingModel:
        return l10n.cameraStatusDownloadingModel(state.modelLang ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              fit: state.isGalleryImage ? BoxFit.contain : BoxFit.cover,
            )
          else if (state.isGalleryImage)
            const SizedBox.shrink()
          else if (controller != null && controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                  height: controller!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                  child: CameraPreview(controller!),
                ),
              ),
            ),
          // Dark overlay + spinner
          Container(color: Colors.black.withValues(alpha: capturedPath != null ? 0.55 : 0.0)),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.95, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOutSine,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                margin: EdgeInsets.all(24.r),
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE6A44A).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFE6A44A)),
                    SizedBox(height: 16.h),
                    Text(
                      _statusLabel(l10n),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
