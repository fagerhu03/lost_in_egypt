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
import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_constants.dart';

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

    if (state is CameraSphinxSecret) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _buildSphinxDialog(dialogContext),
        );
      });
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE6A44A)));
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
                            ? AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: CameraPreview(controller),
                              )
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
  Widget _buildSphinxDialog(BuildContext dialogContext) {
    bool isAnswered = false;
    bool isCorrect = false;
    dynamic unlockedBadge;

    return StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final Color cardColor = isDark ? theme.colorScheme.surface.withValues(alpha: 0.95) : const Color(0xFFF3F2E4);
        final Color goldColor = const Color(0xFFC79A00);
        final Color textColor = isDark ? Colors.white : const Color(0xFFC79A00);
        final Color bodyTextColor = isDark ? Colors.white70 : Colors.black87;
        
        final Color primaryBtnBg = goldColor;
        final Color primaryBtnText = const Color(0xFF1A1A1A);
        final Color secondaryBtnBg = isDark ? Colors.black26 : const Color(0xFF1E1E1E);
        final Color secondaryBtnText = goldColor;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: goldColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: goldColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Icon(
                  isAnswered ? (isCorrect ? Icons.auto_awesome : Icons.warning_amber_rounded) : Icons.help_outline_rounded,
                  color: isAnswered ? (isCorrect ? goldColor : Colors.red) : goldColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  isAnswered 
                      ? (isCorrect ? "You May Pass 🦁" : "Incorrect, Mortal 🌪️")
                      : "The Sphinx's Riddle 🦁",
                  style: TextStyle(
                    fontFamily: "Marcellus",
                    color: isAnswered ? (isCorrect ? textColor : Colors.red) : textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Content
                Text(
                  isAnswered
                      ? (isCorrect 
                          ? "Your wisdom equals the ancients. The Sphinx permits your journey to continue." 
                          : "The sands of time will swallow your ignorance. Return when you have learned.")
                      : "\"What walks on four legs in the morning, two at noon, and three in the evening?\"",
                  style: TextStyle(
                    color: bodyTextColor,
                    fontSize: 18,
                    fontFamily: isAnswered ? null : "Marcellus",
                    fontStyle: isAnswered ? FontStyle.normal : FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Actions
                if (isAnswered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBtnBg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Capture a valid top-level context BEFORE we pop the dialog
                        final validContext = Navigator.of(context, rootNavigator: true).context;
                        
                        Navigator.pop(dialogContext);
                        _cameraCubit.resetToReady();
                        
                        if (isCorrect && unlockedBadge != null) {
                          // Wait for the popup collapse animation to finish
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (validContext.mounted) {
                              BadgeUnlockDialog.show(validContext, unlockedBadge);
                            }
                          });
                        }
                      },
                      child: Text(
                        "Continue",
                        style: TextStyle(color: primaryBtnText, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryBtnBg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: secondaryBtnText.withValues(alpha: 0.3), width: 1),
                          ),
                          onPressed: () => setState(() { isAnswered = true; isCorrect = false; }),
                          child: Text("An Animal", style: TextStyle(color: secondaryBtnText)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryBtnBg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: secondaryBtnText.withValues(alpha: 0.3), width: 1),
                          ),
                          onPressed: () async {
                            setState(() { isAnswered = true; isCorrect = true; });
                            // Fire and wait for unlock check to see if we actually unlocked it
                            unlockedBadge = await _cameraCubit.unlockSecretBadge('sphinx_solver');
                          },
                          child: Text("A Human", style: TextStyle(color: secondaryBtnText)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
