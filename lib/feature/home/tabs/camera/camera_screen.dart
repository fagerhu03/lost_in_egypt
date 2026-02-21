import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/services/ai_storyteller_service.dart';
import '../home/data/models/map_item_models.dart';
import 'ar_overlay_painter.dart';
import '../map/services/map_focus_service.dart';
import 'presentation/bloc/camera_cubit.dart';
import 'presentation/bloc/camera_state.dart';

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
    _cameraCubit = CameraCubit();
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
      return _buildErrorScreen(state);
    }

    if (state is CameraInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE6A44A)),
      );
    }

    if (state is CameraAnalyzing) {
      return _buildAnalyzingScreen(state);
    }

    if (state is CameraNoLandmarkFound) {
      return _buildNoLandmarkScreen(state);
    }

    if (state is CameraLandmarkIdentified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultSheet(state.place);
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

  Widget _buildErrorScreen(CameraError state) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.isApiKeyError ? Icons.key_off : Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  state.isApiKeyError ? 'Configuration Error' : 'Error',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => MapFocusService.instance.switchToTab(0),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _cameraCubit.initCamera(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6A44A),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingScreen(CameraAnalyzing state) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show either camera preview or gallery image
          if (state.isGalleryImage)
            // During gallery analysis, show placeholder
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFE6A44A)),
            )
          else if (_cameraCubit.controller != null && 
              _cameraCubit.controller!.value.isInitialized)
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: CameraPreview(_cameraCubit.controller!),
            ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE6A44A)),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing image...',
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

  Widget _buildNoLandmarkScreen(CameraNoLandmarkFound state) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraCubit.controller != null && 
              _cameraCubit.controller!.value.isInitialized)
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: CameraPreview(_cameraCubit.controller!),
            ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.search_off,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.identifiedLabel != null
                        ? 'We found "${state.identifiedLabel}" but it\'s not in our database'
                        : 'Could not identify any landmark',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _cameraCubit.resetToReady(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6A44A),
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
          // Show gallery image OR camera preview
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: showGalleryImage
                ? Image.file(
                    File(galleryImagePath),
                    fit: BoxFit.contain,
                  )
                : (controller != null && controller.value.isInitialized
                    ? CameraPreview(controller)
                    : const Center(child: CircularProgressIndicator())),
          ),
          
          // AR Overlay
          if (isTranslateMode && recognizedText != null && imageSize != null)
            Positioned.fill(
              child: CustomPaint(
                painter: AROverlayPainter(
                  recognizedText: recognizedText,
                  imageSize: imageSize,
                  // For gallery images, assume no rotation
                  rotation: showGalleryImage 
                      ? InputImageRotation.rotation0deg
                      : (controller != null 
                          ? (InputImageRotationValue.fromRawValue(
                              controller.description.sensorOrientation,
                            ) ?? InputImageRotation.rotation0deg)
                          : InputImageRotation.rotation0deg),
                  translations: translations,
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          if (showGalleryImage) {
                            _cameraCubit.clearGalleryImage();
                          } else {
                            MapFocusService.instance.switchToTab(0);
                          }
                        },
                      ),
                      Text(
                        showGalleryImage ? "Translation" : "Lens",
                        style: const TextStyle(
                          fontFamily: "Marcellus",
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: showGalleryImage 
                            ? null 
                            : () => _cameraCubit.flipCamera(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: "translate_btn",
                          onPressed: () => _cameraCubit.toggleTranslateMode(),
                          backgroundColor: isTranslateMode
                              ? Colors.greenAccent
                              : Colors.white24,
                          child: Icon(
                            Icons.translate,
                            color: isTranslateMode
                                ? Colors.black87
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "AR Trans",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isTranslateMode)
                          _buildLanguageDropdown(
                            value: state.sourceLang,
                            onChanged: (newLang) => _cameraCubit.setSourceLanguage(newLang),
                          ),
                        const SizedBox(height: 8),
                        if (isTranslateMode)
                          _buildLanguageDropdown(
                            value: state.targetLang,
                            onChanged: (newLang) => _cameraCubit.setTargetLanguage(newLang),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 40,
                    left: 30,
                    right: 30,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => _cameraCubit.pickFromGallery(),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTranslateMode
                                ? Icons.translate_outlined
                                : Icons.photo_library_outlined,
                            color: const Color(0xFF4A3D2E),
                          ),
                        ),
                      ),
                      // Hide capture button when showing gallery image
                      if (!showGalleryImage)
                        GestureDetector(
                          onTap: () => _cameraCubit.captureAndAnalyze(),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFFDF4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search,
                                size: 36,
                                color: Color(0xFF4A3D2E),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 84),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String value,
    required Function(String) onChanged,
  }) {
    final languages = CameraCubit.availableLanguages.keys.toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: languages.map<DropdownMenuItem<String>>((String lang) {
            return DropdownMenuItem<String>(value: lang, child: Text(lang));
          }).toList(),
        ),
      ),
    );
  }

  void _showResultSheet(PlaceModel place) {
    String? story;
    bool isLoadingStory = false;
    bool isSpeaking = false;
    bool showFullDescription = false;
    final FlutterTts tts = FlutterTts();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFDF4),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Image.network(
                          place.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.title,
                            style: const TextStyle(
                              fontFamily: "Marcellus",
                              fontSize: 26,
                              color: Color(0xFF4A3D2E),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFE6A44A),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Landmark Identified",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          // Description with Read More
                          if (story == null) ...[
                            Text(
                              showFullDescription 
                                  ? place.description 
                                  : place.description.length > 100 
                                      ? '${place.description.substring(0, 100)}...' 
                                      : place.description,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (place.description.length > 100)
                              TextButton(
                                onPressed: () {
                                  setSheetState(() {
                                    showFullDescription = !showFullDescription;
                                  });
                                },
                                child: Text(
                                  showFullDescription ? 'Read Less' : 'Read More',
                                  style: const TextStyle(
                                    color: Color(0xFFE6A44A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ] else
                            Container(
                              height: 150,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6A44A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFE6A44A,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  story!,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF4A3D2E),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          if (story == null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isLoadingStory
                                    ? null
                                    : () async {
                                        setSheetState(
                                          () => isLoadingStory = true,
                                        );
                                        final storyResult =
                                            await AIStorytellerService.getLandmarkStory(
                                              place.title,
                                            );
                                        setSheetState(() {
                                          story = storyResult;
                                          isLoadingStory = false;
                                        });
                                      },
                                icon: isLoadingStory
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                      ),
                                label: Text(
                                  isLoadingStory
                                      ? "Consulting history..."
                                      : "Tell me a story",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE6A44A),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (isSpeaking) {
                                        await tts.stop();
                                        setSheetState(
                                          () => isSpeaking = false,
                                        );
                                      } else {
                                        setSheetState(() => isSpeaking = true);
                                        await tts.speak(story!);
                                        tts.setCompletionHandler(() {
                                          setSheetState(
                                            () => isSpeaking = false,
                                          );
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      isSpeaking
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      isSpeaking ? "Stop" : "Listen to Story",
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE6A44A),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    MapFocusService.instance.triggerFocus(
                                      place,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    color: Color(0xFF4D5420),
                                  ),
                                  label: const Text(
                                    "Show on Map",
                                    style: TextStyle(color: Color(0xFF4D5420)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF4D5420),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4D5420),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "Done",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
