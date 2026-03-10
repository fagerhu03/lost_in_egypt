import 'dart:io';
import '../../data/models/tour_model.dart';
import '../../data/models/booking_model.dart';

abstract class ToursDataSource {
  Future<void> createTour(TourModel tour, List<File> imageFiles);
  Future<List<TourModel>> getToursForGuide(String guideId);
  Future<List<TourModel>> getAllTours();
  Stream<List<TourModel>> getToursStream();
  Future<void> bookTour(BookingModel booking);
}
