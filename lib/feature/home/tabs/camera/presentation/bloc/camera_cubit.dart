import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../../data/datasources/landmark_remote_datasource.dart';
import '../../data/repositories/landmark_repository_impl.dart';
import '../../data/repositories/place_repository_impl.dart';
import '../../../account/domain/badge_constants.dart';
import '../../../account/domain/badge_model.dart';
import '../../../../../../core/utils/error_handler.dart';
import 'camera_state.dart';

/// Camera Cubit using Cubit for state management
class CameraCubit extends Cubit<CameraState> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  
  // Translation & AR
  final TextRecognizer _textRecognizer = TextRecognizer();

  
  // Language map
  static const Map<String, TranslateLanguage> _mlLanguages = {
    'English': TranslateLanguage.english,
    'Arabic': TranslateLanguage.arabic,
    'French': TranslateLanguage.french,
    'Spanish': TranslateLanguage.spanish,
    'German': TranslateLanguage.german,
    'Italian': TranslateLanguage.italian,
    'Portuguese': TranslateLanguage.portuguese,
    'Russian': TranslateLanguage.russian,
    'Chinese': TranslateLanguage.chinese,
    'Japanese': TranslateLanguage.japanese,
    'Korean': TranslateLanguage.korean,
    'Hindi': TranslateLanguage.hindi,
  };

  // Repositories
  final LandmarkRepositoryImpl _landmarkRepository;
  final PlaceRepositoryImpl _placeRepository;
  final ImagePicker _imagePicker;

  String _sourceLang = 'English';
  String _targetLang = 'Arabic';

  CameraCubit({
    LandmarkRepositoryImpl? landmarkRepository,
    required PlaceRepositoryImpl placeRepository,
    ImagePicker? imagePicker,
  })  : _landmarkRepository = landmarkRepository ?? LandmarkRepositoryImpl(),
        _placeRepository = placeRepository,
        _imagePicker = imagePicker ?? ImagePicker(),
        super(const CameraInitial());

  /// Check if camera is ready
  bool get isCameraReady => state is CameraReady;

  /// Get the camera controller if ready
  CameraController? get controller => _controller;

  /// Get available languages
  static Map<String, TranslateLanguage> get availableLanguages => _mlLanguages;

  /// Current source language
  String get sourceLang => _sourceLang;

  /// Current target language
  String get targetLang => _targetLang;

  /// Initialize the camera
  Future<void> initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initializeCameraController(_cameras[_selectedCameraIndex]);
      } else {
        emit(const CameraError('No cameras available on this device'));
      }
    } catch (e) {
      emit(const CameraError('Failed to initialize camera. Please restart the app.'));
    }
  }

  Future<void> _initializeCameraController(CameraDescription camera) async {
    final previousController = _controller;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    if (previousController != null) {
      await previousController.stopImageStream().catchError((_) {});
      await previousController.dispose();
    }

    try {
      await _controller!.initialize();
      
      // Get min and max zoom levels
      double minZoom = 1.0;
      double maxZoom = 1.0;
      try {
        minZoom = await _controller!.getMinZoomLevel();
        maxZoom = await _controller!.getMaxZoomLevel();
      } catch (_) {}

      // Models will be downloaded on-demand when translating
      
      emit(CameraReady(
        controller: _controller!,
        minZoom: minZoom,
        maxZoom: maxZoom,
        currentZoom: minZoom,
        flashMode: FlashMode.auto,
      ));
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      emit(const CameraError('Failed to initialize camera. Please restart the app.'));
    }
  }



  /// Flip to the other camera
  void flipCamera() {
    if (_cameras.length < 2) return;
    
    if (state is CameraReady) {
      final currentState = state as CameraReady;
      if (currentState.isTranslateMode) {
        toggleTranslateMode();
      }
    }
    
    _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  /// Toggle AR translation mode
  Future<void> toggleTranslateMode() async {
    if (state is! CameraReady) return;

    final currentState = state as CameraReady;
    final newMode = !currentState.isTranslateMode;

    if (newMode) {
      // Switch to translate mode immediately — don't show CameraAnalyzing
      // Models download in the background; stream starts once ready
      emit(currentState.copyWith(
        isTranslateMode: true,
        clearRecognizedText: true,
        translations: {},
        clearGalleryImage: true,
      ));

      // Don't block, download in background
      _downloadModelsIfNeeded().catchError((_) {});
    } else {
      emit(currentState.copyWith(
        isTranslateMode: false,
        clearRecognizedText: true,
        translations: {},
        clearGalleryImage: true,
      ));
    }
  }

  Future<void> _downloadModelsIfNeeded() async {
    final modelManager = OnDeviceTranslatorModelManager();
    final sourceMlLang = _mlLanguages[_sourceLang]!;
    final targetMlLang = _mlLanguages[_targetLang]!;

    final sourceDownloaded = await modelManager.isModelDownloaded(sourceMlLang.bcpCode);
    final targetDownloaded = await modelManager.isModelDownloaded(targetMlLang.bcpCode);

    if (!sourceDownloaded) {
      if (state is CameraAnalyzing) {
        final currentState = state as CameraAnalyzing;
        emit(CameraAnalyzing(
          isGalleryImage: currentState.isGalleryImage,
          capturedImagePath: currentState.capturedImagePath,
          message: "Downloading $_sourceLang model (this may take a minute)...",
        ));
      }
      await modelManager.downloadModel(sourceMlLang.bcpCode).timeout(const Duration(seconds: 45));
    }
    
    if (!targetDownloaded) {
      if (state is CameraAnalyzing) {
        final currentState = state as CameraAnalyzing;
        emit(CameraAnalyzing(
          isGalleryImage: currentState.isGalleryImage,
          capturedImagePath: currentState.capturedImagePath,
          message: "Downloading $_targetLang model (this may take a minute)...",
        ));
      }
      await modelManager.downloadModel(targetMlLang.bcpCode).timeout(const Duration(seconds: 45));
    }
  }



  /// Pick image from gallery for landmark detection
  Future<void> pickFromGallery() async {
    if (state is! CameraReady) return;
    
    final currentState = state as CameraReady;
    if (currentState.isTranslateMode) {
      await _pickFromGalleryForTranslation();
    } else {
      await _pickFromGalleryForLandmark();
    }
  }

  Future<void> _pickFromGalleryForLandmark() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        return;
      }

      emit(CameraAnalyzing(
        isGalleryImage: true,
        capturedImagePath: image.path,
        message: "Identifying landmark...",
      ));

      // Easter Egg: The Sphinx's Riddle
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      for (final TextBlock block in recognizedText.blocks) {
        final lowerText = block.text.trim().toLowerCase();
        if (lowerText.contains("riddle") || lowerText.contains("sphinx")) {
          emit(const CameraSphinxSecret());
          return;
        }
      }

      // Identify landmark using repository
      final landmark = await _landmarkRepository.identifyLandmark(File(image.path));

      if (landmark == null) {
        // DON'T auto-return - let user dismiss manually
        emit(const CameraNoLandmarkFound());
        return;
      }

      // Fetch place from Google Places API
      final place = await _placeRepository.getPlaceByTitle(landmark.name);

      if (place == null) {
        // Found landmark but not in database - DON'T auto-return
        emit(CameraNoLandmarkFound(identifiedLabel: landmark.name));
        return;
      }

      final unlockedBadge = await _recordLandmarkVisit(place.id);
      emit(CameraLandmarkIdentified(place, newlyUnlockedBadge: unlockedBadge));
      
    } on LandmarkDetectionException catch (e) {
      debugPrint("Landmark detection error: $e");
      emit(CameraError(e.message, isApiKeyError: e.isApiKeyError));
    } catch (e) {
      debugPrint("General error: $e");
      emit(CameraError(ErrorHandler.handleGenericError(e)));
    }
  }

  Future<void> _pickFromGalleryForTranslation() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        return;
      }

      await _processImageForTranslation(image.path);
    } catch (e) {
      debugPrint("Gallery translation error: $e");
      emit(CameraError(ErrorHandler.handleGenericError(e)));
    }
  }

  Future<void> _processImageForTranslation(String imagePath) async {
    try {
      emit(const CameraAnalyzing(isGalleryImage: true, message: "Translating..."));

      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Get image size for overlay
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      final imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Easter Egg: The Sphinx's Riddle
      for (final TextBlock block in recognizedText.blocks) {
        final lowerText = block.text.trim().toLowerCase();
        if (lowerText.contains("riddle") || lowerText.contains("sphinx")) {
          emit(const CameraSphinxSecret());
          return;
        }
      }

      // Ensure models are downloaded before translating
      try {
        await _downloadModelsIfNeeded();
      } catch (e) {
        debugPrint("Failed to initialize translation: $e");
        emit(const CameraError('Could not download translation models. Please check your internet connection.'));
        return;
      }

      Map<String, String> currentTranslations = await _translateExistingText(recognizedText);

      if (recognizedText.blocks.any((block) => block.text.trim().isNotEmpty)) {
        // Show the gallery image with AR overlay!
        emit(CameraReady(
          controller: _controller,
          isTranslateMode: true,
          recognizedText: recognizedText,
          imageSize: imageSize,
          translations: currentTranslations,
          sourceLang: _sourceLang,
          targetLang: _targetLang,
          galleryImagePath: imagePath,
        ));
      } else {
        emit(const CameraError('No text found in the selected image.'));
      }
    } catch (e) {
      debugPrint("Translation error: $e");
      emit(CameraError(ErrorHandler.handleGenericError(e)));
    }
  }

  /// Capture and analyze current camera view
  Future<void> captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state is CameraAnalyzing) return;

    final wasTranslateMode = state is CameraReady && (state as CameraReady).isTranslateMode;

    try {
      HapticFeedback.lightImpact();

      // Emit a transient capturing state
      emit(wasTranslateMode 
          ? const CameraAnalyzing(isGalleryImage: true, message: "Capturing...") 
          : const CameraAnalyzing(message: "Capturing..."));

      final XFile imageFile = await _controller!.takePicture();

      // Re-emit with the captured image path so the UI can show a still preview
      if (!wasTranslateMode) {
        emit(CameraAnalyzing(capturedImagePath: imageFile.path, message: "Identifying landmark..."));
      } else {
        emit(const CameraAnalyzing(isGalleryImage: true, message: "Translating..."));
      }
      
      // If we are translating, just freeze and show translation immediately
      // without triggering Gamification gamification or API calls.
      if (wasTranslateMode) {
        await _processImageForTranslation(imageFile.path);
        return;
      }

      // Easter Egg: The Sphinx's Riddle
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      for (final TextBlock block in recognizedText.blocks) {
        final lowerText = block.text.trim().toLowerCase();
        if (lowerText.contains("riddle") || lowerText.contains("sphinx")) {
          emit(const CameraSphinxSecret());
          return;
        }
      }

      final landmark = await _landmarkRepository.identifyLandmark(File(imageFile.path));

      if (landmark == null) {
        // DON'T auto-return - let user dismiss manually
        emit(const CameraNoLandmarkFound());
        return;
      }

      final place = await _placeRepository.getPlaceByTitle(landmark.name);

      if (place == null) {
        // Found landmark but not in database - DON'T auto-return
        emit(CameraNoLandmarkFound(identifiedLabel: landmark.name));
        return;
      }

      final unlockedBadge = await _recordLandmarkVisit(place.id);
      emit(CameraLandmarkIdentified(place, newlyUnlockedBadge: unlockedBadge));
      
    } on LandmarkDetectionException catch (e) {
      debugPrint("Landmark detection error: $e");
      emit(CameraError(e.message, isApiKeyError: e.isApiKeyError));
    } catch (e) {
      debugPrint("Capture error: $e");
      emit(CameraError(ErrorHandler.handleGenericError(e)));
    }
  }

  /// Change source language for translation
  Future<void> setSourceLanguage(String lang) async {
    _sourceLang = lang;
    if (state is CameraReady && (state as CameraReady).isTranslateMode) {
      final currentState = state as CameraReady;
      
      if (currentState.galleryImagePath != null) {
        emit(CameraAnalyzing(
          isGalleryImage: true, 
          message: "Translating...",
          capturedImagePath: currentState.galleryImagePath,
        ));
          
        try {
          await _downloadModelsIfNeeded();
          
          if (currentState.recognizedText != null) {
            final newTranslations = await _translateExistingText(currentState.recognizedText!);
            emit(currentState.copyWith(
              sourceLang: lang,
              translations: newTranslations,
            ));
          }
        } catch (e) {
          emit(const CameraError('Failed to download language model. Please check your internet connection.'));
        }
      } else {
        emit(currentState.copyWith(
          sourceLang: lang,
          clearRecognizedText: true,
          translations: {},
        ));
        
        // Run in background, don't block the live camera
        _downloadModelsIfNeeded().catchError((_) {});
      }
    } else if (state is CameraReady) {
      emit((state as CameraReady).copyWith(sourceLang: lang));
      _downloadModelsIfNeeded().catchError((_) {});
    }
  }

  /// Change target language for translation
  Future<void> setTargetLanguage(String lang) async {
    _targetLang = lang;
    if (state is CameraReady && (state as CameraReady).isTranslateMode) {
      final currentState = state as CameraReady;
      
      if (currentState.galleryImagePath != null) {
        emit(CameraAnalyzing(
          isGalleryImage: true, 
          message: "Translating...",
          capturedImagePath: currentState.galleryImagePath,
        ));
          
        try {
          await _downloadModelsIfNeeded();
          
          if (currentState.recognizedText != null) {
            final newTranslations = await _translateExistingText(currentState.recognizedText!);
            emit(currentState.copyWith(
              targetLang: lang,
              translations: newTranslations,
            ));
          }
        } catch (e) {
          emit(const CameraError('Failed to download language model. Please check your internet connection.'));
        }
      } else {
        emit(currentState.copyWith(
          targetLang: lang,
          clearRecognizedText: true,
          translations: {},
        ));
        
        // Run in background, don't block the live camera
        _downloadModelsIfNeeded().catchError((_) {});
      }
    } else if (state is CameraReady) {
      emit((state as CameraReady).copyWith(targetLang: lang));
      _downloadModelsIfNeeded().catchError((_) {});
    }
  }

  Future<Map<String, String>> _translateExistingText(RecognizedText text) async {
    Map<String, String> currentTranslations = {};
    
    // Create local translator to guarantee correct languages and prevent race conditions
    final translator = OnDeviceTranslator(
      sourceLanguage: _mlLanguages[_sourceLang]!,
      targetLanguage: _mlLanguages[_targetLang]!,
    );
    
    for (final TextBlock block in text.blocks) {
      final originalText = block.text.trim();
      if (originalText.isNotEmpty) {
        try {
          final translated = await translator.translateText(originalText);
          currentTranslations[originalText] = translated;
        } catch (e) {
          debugPrint("Translation error: $e");
          currentTranslations[originalText] = originalText;
        }
      }
    }
    
    try {
      await translator.close();
    } catch (_) {}
    
    return currentTranslations;
  }

  /// Return to ready state - called when user dismisses dialog
  void resetToReady() {
    if (_controller != null && _controller!.value.isInitialized) {
      // Re-query current states just in case
      final flash = _controller!.value.flashMode;
      emit(CameraReady(
        controller: _controller!,
        flashMode: flash,
        isTranslateMode: false,
      ));
    } else {
      initCamera();
    }
  }

  /// Clear gallery image and return to live camera
  void clearGalleryImage() {
    if (state is CameraReady) {
      emit((state as CameraReady).copyWith(
        clearGalleryImage: true,
        clearRecognizedText: true,
        translations: {},
      ));
    }
  }

  /// Toggle flash mode
  Future<void> toggleFlash() async {
    if (state is! CameraReady || _controller == null) return;
    
    final currentState = state as CameraReady;
    FlashMode nextMode;
    switch (currentState.flashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      emit(currentState.copyWith(flashMode: nextMode));
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (state is! CameraReady || _controller == null) return;
    final currentState = state as CameraReady;

    double safeZoom = zoom;
    if (safeZoom < currentState.minZoom) safeZoom = currentState.minZoom;
    if (safeZoom > currentState.maxZoom) safeZoom = currentState.maxZoom;

    try {
      // Don't await the native call to prevent lag during continuous pinch/slider updates
      _controller!.setZoomLevel(safeZoom).catchError((_) {});
      emit(currentState.copyWith(currentZoom: safeZoom));
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  /// Gamification: Record visited landmark
  Future<BadgeModel?> _recordLandmarkVisit(String placeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      return await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return null;
        
        final data = doc.data()!;
        List<String> visited = List<String>.from(data['visitedLandmarks'] ?? []);
        
        if (!visited.contains(placeId)) {
          visited.add(placeId);
          transaction.update(userRef, {'visitedLandmarks': visited});
          
          final newCount = visited.length;
          try {
            return BadgeConstants.allBadges.firstWhere((b) => b.requiredVisits == newCount);
          } catch (_) {
            return null;
          }
        }
        return null;
      });
    } catch (e) {
      debugPrint("Error recording landmark visit: $e");
      return null;
    }
  }

  /// Gamification: Unlock Secret Badge
  Future<BadgeModel?> unlockSecretBadge(String badgeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Get current data first (reads from cache if offline)
      final doc = await userRef.get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      List<String> visited = List<String>.from(data['visitedLandmarks'] ?? []);
      
      if (!visited.contains(badgeId)) {
        // Fire and forget update to support offline unlocks
        userRef.update({'visitedLandmarks': FieldValue.arrayUnion([badgeId])});
        
        try {
          return BadgeConstants.allBadges.firstWhere((b) => b.id == badgeId);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error unlocking secret badge: $e");
      return null;
    }
  }

  @override
  Future<void> close() async {
    _controller?.dispose();
    _textRecognizer.close();
    return super.close();
  }
}
