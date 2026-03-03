import 'dart:io';
import '../../data/models/tour_model.dart';
import '../../domain/entities/tour_entity.dart';

abstract class ToursDataSource {
  Future<void> createTour(TourModel tour, List<File> imageFiles);
  Future<List<TourModel>> getToursForGuide(String guideId);
  Future<List<TourModel>> getAllTours();
}
