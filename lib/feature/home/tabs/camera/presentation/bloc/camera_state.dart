import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../home/data/models/map_item_models.dart';
import '../../../account/domain/badge_model.dart';

/// Represents the different states of the camera feature
abstract class CameraState {
  const CameraState();
}

/// Initial state when camera is loading
class CameraInitial extends CameraState {
  const CameraInitial();
}

/// Camera is ready but not analyzing
class CameraReady extends CameraState {
  final CameraController? controller;
  final bool isTranslateMode;
  final RecognizedText? recognizedText;
  final Map<String, String> translations;
  final Size? imageSize;
  final String sourceLang;
  final String targetLang;
  
  // For showing gallery image with translation overlay
  final String? galleryImagePath;

  const CameraReady({
    this.controller,
    this.isTranslateMode = false,
    this.recognizedText,
    this.translations = const {},
    this.imageSize,
    this.sourceLang = 'English',
    this.targetLang = 'Arabic',
    this.galleryImagePath,
  });

  /// Check if we're showing a gallery image (not live camera)
  bool get isShowingGalleryImage => galleryImagePath != null;

  CameraReady copyWith({
    CameraController? controller,
    bool? isTranslateMode,
    RecognizedText? recognizedText,
    Map<String, String>? translations,
    Size? imageSize,
    String? sourceLang,
    String? targetLang,
    String? galleryImagePath,
    bool clearRecognizedText = false,
    bool clearGalleryImage = false,
  }) {
    return CameraReady(
      controller: controller ?? this.controller,
      isTranslateMode: isTranslateMode ?? this.isTranslateMode,
      recognizedText: clearRecognizedText ? null : (recognizedText ?? this.recognizedText),
      translations: translations ?? this.translations,
      imageSize: imageSize ?? this.imageSize,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      galleryImagePath: clearGalleryImage ? null : (galleryImagePath ?? this.galleryImagePath),
    );
  }
}

/// Currently analyzing an image
class CameraAnalyzing extends CameraState {
  final bool isGalleryImage;
  
  const CameraAnalyzing({this.isGalleryImage = false});
}

/// Successfully identified a landmark
class CameraLandmarkIdentified extends CameraState {
  final PlaceModel place;
  final BadgeModel? newlyUnlockedBadge;

  const CameraLandmarkIdentified(this.place, {this.newlyUnlockedBadge});
}

/// No landmark found in the image - needs user action to dismiss
class CameraNoLandmarkFound extends CameraState {
  final String? identifiedLabel;

  const CameraNoLandmarkFound({this.identifiedLabel});
}

/// Error state
class CameraError extends CameraState {
  final String message;
  final bool isApiKeyError;

  const CameraError(this.message, {this.isApiKeyError = false});
}
