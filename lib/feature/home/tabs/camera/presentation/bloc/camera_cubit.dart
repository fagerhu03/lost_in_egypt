import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../../home/data/models/map_item_models.dart';
import '../../data/datasources/landmark_remote_datasource.dart';
import '../../data/repositories/landmark_repository_impl.dart';
import '../../data/repositories/place_repository_impl.dart';
import 'camera_state.dart';

/// Camera Cubit using ChangeNotifier for state management
class CameraCubit extends ChangeNotifier {
  CameraState _state = const CameraInitial();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  
  // Translation
  final TextRecognizer _textRecognizer = TextRecognizer();
  OnDeviceTranslator? _translator;
  bool _isProcessingFrame = false;
  bool _translatorInitialized = false;
  
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
    PlaceRepositoryImpl? placeRepository,
    ImagePicker? imagePicker,
  })  : _landmarkRepository = landmarkRepository ?? LandmarkRepositoryImpl(),
        _placeRepository = placeRepository ?? PlaceRepositoryImpl(),
        _imagePicker = imagePicker ?? ImagePicker();

  /// Current state
  CameraState get state => _state;

  /// Check if camera is ready
  bool get isCameraReady => _state is CameraReady;

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
        _emit(const CameraError('No cameras available on this device'));
      }
    } catch (e) {
      _emit(CameraError('Failed to initialize camera: $e'));
    }
  }

  void _emit(CameraState newState) {
    _state = newState;
    notifyListeners();
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
      
      // Initialize translator but don't fail if it doesn't work
      await _initTranslator();
      
      _emit(CameraReady(controller: _controller!));
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      _emit(CameraError('Failed to initialize camera: $e'));
    }
  } 

  Future<void> _initTranslator() async {
    try {
      try {
        _translator?.close();
      } catch (_) {}

      _translator = OnDeviceTranslator(
        sourceLanguage: _mlLanguages[_sourceLang]!,
        targetLanguage: _mlLanguages[_targetLang]!,
      );
      _translatorInitialized = true;
    } catch (e) {
      debugPrint("Failed to initialize translator: $e");
      _translatorInitialized = false;
    }
  }

  /// Flip to the other camera
  void flipCamera() {
    if (_cameras.length < 2) return;
    
    if (_state is CameraReady) {
      final currentState = _state as CameraReady;
      if (currentState.isTranslateMode) {
        toggleTranslateMode();
      }
    }
    
    _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  /// Toggle AR translation mode
  Future<void> toggleTranslateMode() async {
    if (_state is! CameraReady) return;
    
    final currentState = _state as CameraReady;
    final newMode = !currentState.isTranslateMode;
    
    if (newMode) {
      _emit(const CameraAnalyzing());
      
      try {
        await _downloadModelsIfNeeded();
        
        // Re-emit CameraReady with translation mode on
        _emit(currentState.copyWith(
          isTranslateMode: true,
          clearRecognizedText: true,
          translations: {},
          clearGalleryImage: true,
        ));
        
        if (_controller != null && _controller!.value.isInitialized) {
          _startImageStream();
        }
      } catch (e) {
        debugPrint("Failed to initialize translation: $e");
        _emit(CameraError('Failed to initialize translation models. Please check your internet connection.'));
        return;
      }
    } else {
      _stopImageStream();
      _emit(currentState.copyWith(
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

    bool sourceDownloaded = await modelManager.isModelDownloaded(sourceMlLang.bcpCode);
    bool targetDownloaded = await modelManager.isModelDownloaded(targetMlLang.bcpCode);

    if (!sourceDownloaded) {
      await modelManager.downloadModel(sourceMlLang.bcpCode);
    }
    if (!targetDownloaded) {
      await modelManager.downloadModel(targetMlLang.bcpCode);
    }

    _translator = OnDeviceTranslator(
      sourceLanguage: sourceMlLang,
      targetLanguage: targetMlLang,
    );
    _translatorInitialized = true;
  }


  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) {
      if (_isProcessingFrame || _state is! CameraReady) return;
      final currentState = _state as CameraReady;
      if (!currentState.isTranslateMode) return;
      if (currentState.galleryImagePath != null) return; // Prevent live stream from overwriting gallery mode
      
      _processCameraImage(image);
    });
  }

  void _stopImageStream() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_translatorInitialized || _translator == null) return;
    
    _isProcessingFrame = true;
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(
            _controller!.description.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );
      
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (_state is CameraReady) {
        final currentState = _state as CameraReady;
        if (!currentState.isTranslateMode) return;
        
        // Perform translation
        Map<String, String> currentTranslations = {};
        for (final TextBlock block in recognizedText.blocks) {
          final originalText = block.text.trim();
          if (originalText.isNotEmpty && _translator != null) {
            try {
              final translated = await _translator!.translateText(originalText);
              currentTranslations[originalText] = translated;
            } catch (e) {
              debugPrint("Translation error: $e");
              currentTranslations[originalText] = originalText;
            }
          }
        }

        _emit(currentState.copyWith(
          recognizedText: recognizedText,
          imageSize: imageSize,
          translations: currentTranslations,
        ));
      }
    } catch (e) {
      debugPrint("Error processing frame: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Pick image from gallery for landmark detection
  Future<void> pickFromGallery() async {
    if (_state is! CameraReady) return;
    
    final currentState = _state as CameraReady;
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

      _emit(const CameraAnalyzing());

      // Identify landmark using repository
      final landmark = await _landmarkRepository.identifyLandmark(File(image.path));

      if (landmark == null) {
        // DON'T auto-return - let user dismiss manually
        _emit(const CameraNoLandmarkFound());
        return;
      }

      // Fetch place from Firestore
      final placeDoc = await _placeRepository.getPlaceByTitle(landmark.name);

      if (placeDoc == null) {
        // Found landmark but not in database - DON'T auto-return
        _emit(CameraNoLandmarkFound(identifiedLabel: landmark.name));
        return;
      }

      final place = PlaceModel.fromMap(placeDoc.data(), placeDoc.id);
      _emit(CameraLandmarkIdentified(place));
      
    } on LandmarkDetectionException catch (e) {
      debugPrint("Landmark detection error: $e");
      _emit(CameraError(e.message, isApiKeyError: e.isApiKeyError));
    } catch (e) {
      debugPrint("General error: $e");
      _emit(CameraError('Failed to analyze image: $e'));
    }
  }

  Future<void> _pickFromGalleryForTranslation() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        return;
      }

      _emit(const CameraAnalyzing(isGalleryImage: true));

      final inputImage = InputImage.fromFilePath(image.path);
      
      // Get image size for overlay
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      final imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Try to download translation models if not already done
      if (!_translatorInitialized || _translator == null) {
        try {
          final modelManager = OnDeviceTranslatorModelManager();
          
          final sourceMlLang = _mlLanguages[_sourceLang]!;
          final targetMlLang = _mlLanguages[_targetLang]!;

          bool sourceDownloaded = await modelManager.isModelDownloaded(sourceMlLang.bcpCode);
          bool targetDownloaded = await modelManager.isModelDownloaded(targetMlLang.bcpCode);

          if (!sourceDownloaded) {
            await modelManager.downloadModel(sourceMlLang.bcpCode);
          }
          if (!targetDownloaded) {
            await modelManager.downloadModel(targetMlLang.bcpCode);
          }

          _translator = OnDeviceTranslator(
            sourceLanguage: sourceMlLang,
            targetLanguage: targetMlLang,
          );
          _translatorInitialized = true;
        } catch (e) {
          debugPrint("Failed to initialize translation: $e");
          _emit(CameraError('Translation not available: $e. Please check your internet connection.'));
          return;
        }
      }

      Map<String, String> currentTranslations = await _translateExistingText(recognizedText);

      if (recognizedText.blocks.any((block) => block.text.trim().isNotEmpty)) {
        // Show the gallery image with AR overlay!
        _emit(CameraReady(
          controller: _controller,
          isTranslateMode: true,
          recognizedText: recognizedText,
          imageSize: imageSize,
          translations: currentTranslations,
          sourceLang: _sourceLang,
          targetLang: _targetLang,
          galleryImagePath: image.path,
        ));
      } else {
        _emit(const CameraError('No text found in the selected image.'));
      }
    } catch (e) {
      debugPrint("Translation error: $e");
      _emit(CameraError('Failed to translate image: $e'));
    }
  }

  /// Capture and analyze current camera view
  Future<void> captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_state is CameraAnalyzing) return;

    try {
      _emit(const CameraAnalyzing());

      final XFile imageFile = await _controller!.takePicture();
      final landmark = await _landmarkRepository.identifyLandmark(File(imageFile.path));

      if (landmark == null) {
        // DON'T auto-return - let user dismiss manually
        _emit(const CameraNoLandmarkFound());
        return;
      }

      final placeDoc = await _placeRepository.getPlaceByTitle(landmark.name);

      if (placeDoc == null) {
        // Found landmark but not in database - DON'T auto-return
        _emit(CameraNoLandmarkFound(identifiedLabel: landmark.name));
        return;
      }

      final place = PlaceModel.fromMap(placeDoc.data(), placeDoc.id);
      _emit(CameraLandmarkIdentified(place));
      
    } on LandmarkDetectionException catch (e) {
      debugPrint("Landmark detection error: $e");
      _emit(CameraError(e.message, isApiKeyError: e.isApiKeyError));
    } catch (e) {
      debugPrint("Capture error: $e");
      _emit(CameraError('Failed to analyze image: $e'));
    }
  }

  /// Change source language for translation
  Future<void> setSourceLanguage(String lang) async {
    _sourceLang = lang;
    if (_state is CameraReady && (_state as CameraReady).isTranslateMode) {
      final currentState = _state as CameraReady;
      
      // If we have a gallery image, keep the text and just re-translate
      // Otherwise list clears for live camera
      _emit(currentState.galleryImagePath != null 
          ? const CameraAnalyzing(isGalleryImage: true) 
          : const CameraAnalyzing());
          
      try {
        await _downloadModelsIfNeeded();
        
        if (currentState.galleryImagePath != null && currentState.recognizedText != null) {
          final newTranslations = await _translateExistingText(currentState.recognizedText!);
          _emit(currentState.copyWith(
            sourceLang: lang,
            translations: newTranslations,
          ));
        } else {
          _emit(currentState.copyWith(
            sourceLang: lang,
            clearRecognizedText: true,
            translations: {},
          ));
        }
      } catch (e) {
        _emit(CameraError('Failed to download language model: $e'));
      }
    } else if (_state is CameraReady) {
      _emit((_state as CameraReady).copyWith(sourceLang: lang));
    }
  }

  /// Change target language for translation
  Future<void> setTargetLanguage(String lang) async {
    _targetLang = lang;
    if (_state is CameraReady && (_state as CameraReady).isTranslateMode) {
      final currentState = _state as CameraReady;
      
      // If we have a gallery image, keep the text and just re-translate
      // Otherwise list clears for live camera
      _emit(currentState.galleryImagePath != null 
          ? const CameraAnalyzing(isGalleryImage: true) 
          : const CameraAnalyzing());
          
      try {
        await _downloadModelsIfNeeded();
        
        if (currentState.galleryImagePath != null && currentState.recognizedText != null) {
          final newTranslations = await _translateExistingText(currentState.recognizedText!);
          _emit(currentState.copyWith(
            targetLang: lang,
            translations: newTranslations,
          ));
        } else {
          _emit(currentState.copyWith(
            targetLang: lang,
            clearRecognizedText: true,
            translations: {},
          ));
        }
      } catch (e) {
        _emit(CameraError('Failed to download language model: $e'));
      }
    } else if (_state is CameraReady) {
      _emit((_state as CameraReady).copyWith(targetLang: lang));
    }
  }

  Future<Map<String, String>> _translateExistingText(RecognizedText text) async {
    Map<String, String> currentTranslations = {};
    if (_translator == null) return currentTranslations;
    for (final TextBlock block in text.blocks) {
      final originalText = block.text.trim();
      if (originalText.isNotEmpty) {
        try {
          final translated = await _translator!.translateText(originalText);
          currentTranslations[originalText] = translated;
        } catch (e) {
          debugPrint("Translation error: $e");
          currentTranslations[originalText] = originalText;
        }
      }
    }
    return currentTranslations;
  }

  /// Return to ready state - called when user dismisses dialog
  void resetToReady() {
    if (_controller != null && _controller!.value.isInitialized) {
      _emit(CameraReady(controller: _controller!));
    } else {
      initCamera();
    }
  }

  /// Clear gallery image and return to live camera
  void clearGalleryImage() {
    if (_state is CameraReady) {
      _emit((_state as CameraReady).copyWith(
        clearGalleryImage: true,
        clearRecognizedText: true,
        translations: {},
      ));
    }
  }

  @override
  void dispose() {
    _stopImageStream();
    _controller?.dispose();
    _textRecognizer.close();
    _translator?.close();
    super.dispose();
  }
}
