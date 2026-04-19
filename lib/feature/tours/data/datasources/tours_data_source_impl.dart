import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/models/tour_model.dart';
import '../../data/models/booking_model.dart';
import 'tours_data_source.dart';
import 'package:path/path.dart' as path;
import '../../../../core/utils/image_utils.dart';

class ToursDataSourceImpl implements ToursDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<void> createTour(TourModel tour, List<File> imageFiles) async {
    List<String> imageUrls = [];

    // Upload images
    for (int i = 0; i < imageFiles.length; i++) {
      final file = await ImageUtils.compressImage(imageFiles[i]) ?? imageFiles[i];
      final extension = path.extension(file.path);
      final fileName = '${tour.id}_$i$extension';
      final ref = _storage.ref().child('tours/${tour.guideId}/${tour.id}/$fileName');
      
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    // Update tour with image URLs
    final updatedTour = TourModel(
      id: tour.id,
      guideId: tour.guideId,
      title: tour.title,
      description: tour.description,
      destinations: tour.destinations,
      price: tour.price,
      meetingLocationName: tour.meetingLocationName,
      meetingLatitude: tour.meetingLatitude,
      meetingLongitude: tour.meetingLongitude,
      meetingTime: tour.meetingTime,
      frequency: tour.frequency,
      images: imageUrls,
      maxAttendees: tour.maxAttendees,
      rating: tour.rating,
      reviewCount: tour.reviewCount,
      createdAt: tour.createdAt,
      totalCapacity: tour.totalCapacity,
      recurrenceType: tour.recurrenceType,
      recurrenceDays: tour.recurrenceDays,
      meetingTimeOfDay: tour.meetingTimeOfDay,
      nextOccurrence: tour.nextOccurrence,
      isArchived: tour.isArchived,
    );

    // Save to Firestore
    await _firestore.collection('tours').doc(tour.id).set(updatedTour.toMap());
  }

  @override
  Future<void> updateTour(TourModel tour, List<File> newImageFiles) async {
    List<String> imageUrls = List.from(tour.images);

    // If new images are provided, upload them and append/replace. 
    // Here we append, or if we want to replace we can clear first. Let's append for now, or just let the user send the new ones.
    // For simplicity, if new images are selected, we just add them to the list.
    for (int i = 0; i < newImageFiles.length; i++) {
      final file = await ImageUtils.compressImage(newImageFiles[i]) ?? newImageFiles[i];
      final extension = path.extension(file.path);
      // use a timestamp to avoid overwrite issues with old images
      final fileName = '${tour.id}_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
      final ref = _storage.ref().child('tours/${tour.guideId}/${tour.id}/$fileName');
      
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    final updatedTour = TourModel(
      id: tour.id,
      guideId: tour.guideId,
      title: tour.title,
      description: tour.description,
      destinations: tour.destinations,
      price: tour.price,
      meetingLocationName: tour.meetingLocationName,
      meetingLatitude: tour.meetingLatitude,
      meetingLongitude: tour.meetingLongitude,
      meetingTime: tour.meetingTime,
      frequency: tour.frequency,
      images: imageUrls,
      maxAttendees: tour.maxAttendees,
      rating: tour.rating,
      reviewCount: tour.reviewCount,
      createdAt: tour.createdAt,
      totalCapacity: tour.totalCapacity,
      recurrenceType: tour.recurrenceType,
      recurrenceDays: tour.recurrenceDays,
      meetingTimeOfDay: tour.meetingTimeOfDay,
      nextOccurrence: tour.nextOccurrence,
      isArchived: tour.isArchived,
    );

    await _firestore.collection('tours').doc(tour.id).update(updatedTour.toMap());
  }

  @override
  Future<List<TourModel>> getToursForGuide(String guideId) async {
    final snapshot = await _firestore
        .collection('tours')
        .where('guideId', isEqualTo: guideId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => TourModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<TourModel>> getAllTours() async {
    final snapshot = await _firestore
        .collection('tours')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => TourModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Stream<List<TourModel>> getToursStream() {
    return _firestore
        .collection('tours')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TourModel.fromMap(doc.data(), doc.id)).toList());
  }

  @override
  Future<void> bookTour(BookingModel booking) async {
    final tourRef = _firestore.collection('tours').doc(booking.tourId);
    final bookingRef = _firestore.collection('bookings').doc(booking.id);

    await _firestore.runTransaction((transaction) async {
      // 1. Read Tour inside transaction
      final tourSnapshot = await transaction.get(tourRef);

      if (!tourSnapshot.exists) {
        throw Exception("Tour does not exist.");
      }

      final int currentCapacity = tourSnapshot.data()?['maxAttendees'] ?? 0;

      // 2. Check Capacity
      if (currentCapacity < booking.quantity) {
        throw Exception("Not enough spots available (only $currentCapacity left).");
      }

      // 3. Decrement Capacity by booked quantity
      transaction.update(tourRef, {
        'maxAttendees': currentCapacity - booking.quantity,
      });

      // 4. Create Booking Document
      transaction.set(bookingRef, booking.toMap());
    });
  }
}
