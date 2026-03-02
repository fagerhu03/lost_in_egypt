import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:lost_in_egypt/feature/home/tabs/camera/widgets/ar_bubble_overlay.dart';
import 'package:lost_in_egypt/feature/home/tabs/camera/presentation/bloc/camera_cubit.dart';
import 'package:lost_in_egypt/feature/home/tabs/camera/presentation/bloc/camera_state.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/places_api_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/camera/data/repositories/place_repository_impl.dart';

import '../widgets/camera_error_view.dart';
import '../widgets/camera_analyzing_view.dart';
import '../widgets/camera_no_landmark_view.dart';
import '../widgets/camera_result_sheet.dart';
import '../widgets/camera_overlay_controls.dart';
import '../widgets/badge_unlock_dialog.dart';
import '../widgets/translation_draggable_panel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraCubit _cameraCubit;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    final placesApiService = PlacesApiService(apiKey: apiKey);
    final placeRepository = PlaceRepositoryImpl(
      placesApiService: placesApiService,
      apiKey: apiKey,
    );
    
    _cameraCubit = CameraCubit(placeRepository: placeRepository);
    _cameraCubit.initCamera();
  }

  @override
  void dispose() {
    _cameraCubit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cameraCubit,
      builder: (context, child) {
        return _buildContent();
      },
    );
  }

  Widget _buildContent() {
    final state = _cameraCubit.state;

    if (state is CameraError) {
      return CameraErrorView(state: state, cubit: _cameraCubit);
    }

    if (state is CameraInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE6A44A)),
      );
    }

    if (state is CameraAnalyzing) {
      return CameraAnalyzingView(state: state, controller: _cameraCubit.controller);
    }

    if (state is CameraNoLandmarkFound) {
      return CameraNoLandmarkView(state: state, controller: _cameraCubit.controller, cubit: _cameraCubit);
    }

    if (state is CameraLandmarkIdentified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        CameraResultSheet.show(context, state.place);
        if (state.newlyUnlockedBadge != null) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (context.mounted) {
              BadgeUnlockDialog.show(context, state.newlyUnlockedBadge!);
            }
          });
        }
        _cameraCubit.resetToReady();
      });
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE6A44A)),
      );
    }

    if (state is CameraReady) {
      return _buildCameraScreen(state);
    }

    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFE6A44A)),
    );
  }

  Widget _buildCameraScreen(CameraReady state) {
    final controller = state.controller;
    final isTranslateMode = state.isTranslateMode;
    final recognizedText = state.recognizedText;
    final imageSize = state.imageSize;
    final translations = state.translations;
    final galleryImagePath = state.galleryImagePath;

    // Check if we're showing a gallery image
    final bool showGalleryImage = galleryImagePath != null && isTranslateMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show gallery image OR camera preview with Overlay
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: showGalleryImage
                ? InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    maxScale: 4.0,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            File(galleryImagePath),
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (isTranslateMode && recognizedText != null && imageSize != null)
                          Positioned.fill(
                            child: ARBubbleOverlay(
                              recognizedText: recognizedText,
                              imageSize: imageSize,
                              rotation: InputImageRotation.rotation0deg,
                              translations: translations,
                              targetLang: state.targetLang,
                              widgetSize: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.height,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: (controller != null && controller.value.isInitialized)
                            ? CameraPreview(controller)
                            : const Center(child: CircularProgressIndicator()),
                      ),
                      if (isTranslateMode && recognizedText != null && imageSize != null)
                        Positioned.fill(
                          child: ARBubbleOverlay(
                            recognizedText: recognizedText,
                            imageSize: imageSize,
                            rotation: controller != null 
                                ? (InputImageRotationValue.fromRawValue(
                                    controller.description.sensorOrientation,
                                  ) ?? InputImageRotation.rotation0deg)
                                : InputImageRotation.rotation0deg,
                            translations: translations,
                            targetLang: state.targetLang,
                            widgetSize: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.height,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          
          CameraOverlayControls(
            state: state,
            cubit: _cameraCubit,
            showGalleryImage: showGalleryImage,
          ),

          if (showGalleryImage && translations.isNotEmpty)
            TranslationDraggablePanel(
              translations: translations,
              targetLang: state.targetLang,
            ),
        ],
      ),
    );
  }
}
