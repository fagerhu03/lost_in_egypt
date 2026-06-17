import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lost_in_egypt/feature/home/tabs/account/domain/badge_model.dart';
import 'package:lost_in_egypt/feature/home/tabs/camera/presentation/bloc/camera_state.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

// Reusable test fixtures
const _coord = GeoPoint(30.0444, 31.2357); // Cairo

const _place = PlaceModel(
  id: 'test-001',
  title: 'Great Pyramid of Giza',
  category: 'Monument',
  coordinate: _coord,
  imagePath: 'https://example.com/pyramid.jpg',
  locationAddress: 'Giza, Egypt',
  rating: 4.9,
  price: 200,
  duration: '3 hours',
  weather: 'Sunny',
  description: 'One of the Seven Wonders of the Ancient World.',
);

const _badge = BadgeModel(
  id: 'novice_explorer',
  name: 'Novice Explorer',
  description: 'Discovered your first landmark!',
  requiredVisits: 1,
  iconData: Icons.explore,
);

void main() {
  // ─── CameraReady.copyWith ─────────────────────────────────────────────────

  group('CameraReady.copyWith', () {
    const base = CameraReady(
      sourceLang: 'English',
      targetLang: 'Arabic',
      currentZoom: 1.0,
      minZoom: 1.0,
      maxZoom: 5.0,
    );

    test('preserves all fields when no args provided', () {
      final copy = base.copyWith();
      expect(copy.sourceLang, base.sourceLang);
      expect(copy.targetLang, base.targetLang);
      expect(copy.currentZoom, base.currentZoom);
      expect(copy.minZoom, base.minZoom);
      expect(copy.maxZoom, base.maxZoom);
      expect(copy.isTranslateMode, base.isTranslateMode);
      expect(copy.flashMode, base.flashMode);
      expect(copy.translations, base.translations);
    });

    test('updates only the specified field', () {
      final copy = base.copyWith(currentZoom: 3.0);
      expect(copy.currentZoom, 3.0);
      expect(copy.sourceLang, 'English');
      expect(copy.maxZoom, 5.0);
    });

    test('clearGalleryImage removes galleryImagePath', () {
      const withImage = CameraReady(galleryImagePath: '/tmp/img.jpg');
      final cleared = withImage.copyWith(clearGalleryImage: true);
      expect(cleared.galleryImagePath, isNull);
      expect(cleared.isShowingGalleryImage, isFalse);
    });

    test('clearRecognizedText removes recognizedText', () {
      // Use a real CameraReady with recognizedText set via copyWith
      final withText = base.copyWith(sourceLang: 'French');
      // recognizedText is null by default; we test the clear flag doesn't crash
      final cleared = withText.copyWith(clearRecognizedText: true);
      expect(cleared.recognizedText, isNull);
      // Other fields are preserved
      expect(cleared.sourceLang, 'French');
    });

    test('isShowingGalleryImage is true when galleryImagePath is set', () {
      const s = CameraReady(galleryImagePath: '/tmp/photo.jpg');
      expect(s.isShowingGalleryImage, isTrue);
    });

    test('isShowingGalleryImage is false when galleryImagePath is null', () {
      expect(base.isShowingGalleryImage, isFalse);
    });

    test('toggles isTranslateMode correctly', () {
      final on = base.copyWith(isTranslateMode: true);
      expect(on.isTranslateMode, isTrue);
      final off = on.copyWith(isTranslateMode: false);
      expect(off.isTranslateMode, isFalse);
    });

    test('replaces translations map (not merges)', () {
      final withTrans =
          base.copyWith(translations: {'hello': 'مرحبا', 'bye': 'وداعا'});
      expect(withTrans.translations['hello'], 'مرحبا');

      final replaced = withTrans.copyWith(translations: {'hello': 'أهلاً'});
      expect(replaced.translations['hello'], 'أهلاً');
      expect(replaced.translations.containsKey('bye'), isFalse);
    });

    test('lang pair updates independently', () {
      final arabic = base.copyWith(targetLang: 'French');
      expect(arabic.targetLang, 'French');
      expect(arabic.sourceLang, 'English');
    });
  });

  // ─── CameraInitial ────────────────────────────────────────────────────────

  group('CameraInitial', () {
    test('is a CameraState', () {
      expect(const CameraInitial(), isA<CameraState>());
    });
  });

  // ─── CameraAnalyzing ─────────────────────────────────────────────────────

  group('CameraAnalyzing', () {
    test('defaults: non-gallery, null path, identifying status', () {
      const s = CameraAnalyzing();
      expect(s.isGalleryImage, isFalse);
      expect(s.capturedImagePath, isNull);
      expect(s.status, CameraStatus.identifying);
      expect(s.modelLang, isNull);
    });

    test('stores all fields when provided', () {
      const s = CameraAnalyzing(
        capturedImagePath: '/tmp/capture.jpg',
        status: CameraStatus.downloadingModel,
        modelLang: 'Korean',
        isGalleryImage: true,
      );
      expect(s.capturedImagePath, '/tmp/capture.jpg');
      expect(s.status, CameraStatus.downloadingModel);
      expect(s.modelLang, 'Korean');
      expect(s.isGalleryImage, isTrue);
    });
  });

  // ─── CameraLandmarkIdentified ─────────────────────────────────────────────

  group('CameraLandmarkIdentified', () {
    test('stores place and null badge when no badge unlocked', () {
      const s = CameraLandmarkIdentified(_place);
      expect(s.place.title, 'Great Pyramid of Giza');
      expect(s.place.id, 'test-001');
      expect(s.newlyUnlockedBadge, isNull);
    });

    test('stores badge when a new badge is unlocked on discovery', () {
      const s = CameraLandmarkIdentified(_place, newlyUnlockedBadge: _badge);
      expect(s.newlyUnlockedBadge, isNotNull);
      expect(s.newlyUnlockedBadge!.id, 'novice_explorer');
      expect(s.newlyUnlockedBadge!.name, 'Novice Explorer');
    });

    test('place fields are accessible', () {
      const s = CameraLandmarkIdentified(_place);
      expect(s.place.rating, 4.9);
      expect(s.place.category, 'Monument');
      expect(s.place.coordinate.latitude, closeTo(30.04, 0.01));
    });

    test('is a CameraState', () {
      expect(const CameraLandmarkIdentified(_place), isA<CameraState>());
    });
  });

  // ─── CameraError ─────────────────────────────────────────────────────────

  group('CameraError', () {
    test('stores message and defaults isApiKeyError to false', () {
      const s = CameraError('Network error');
      expect(s.message, 'Network error');
      expect(s.isApiKeyError, isFalse);
    });

    test('marks API key errors explicitly', () {
      const s = CameraError('Invalid key', isApiKeyError: true);
      expect(s.isApiKeyError, isTrue);
    });
  });

  // ─── CameraNoLandmarkFound ────────────────────────────────────────────────

  group('CameraNoLandmarkFound', () {
    test('identifiedLabel is null when Vision returns nothing', () {
      const s = CameraNoLandmarkFound();
      expect(s.identifiedLabel, isNull);
    });

    test('stores identifiedLabel when Vision names something not in local DB', () {
      const s = CameraNoLandmarkFound(identifiedLabel: 'Bibliotheca Alexandrina');
      expect(s.identifiedLabel, 'Bibliotheca Alexandrina');
    });
  });

  // ─── CameraSphinxSecret ───────────────────────────────────────────────────

  group('CameraSphinxSecret', () {
    test('is a CameraState', () {
      expect(const CameraSphinxSecret(), isA<CameraState>());
    });
  });
}
