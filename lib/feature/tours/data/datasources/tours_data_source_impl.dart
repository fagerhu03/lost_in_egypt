import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/models/tour_model.dart';
import '../../data/models/booking_model.dart';
import 'tours_data_source.dart';
import 'package:path/path.dart' as path;

class ToursDataSourceImpl implements ToursDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<void> createTour(TourModel tour, List<File> imageFiles) async {
    List<String> imageUrls = [];

    // Upload images
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
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
    );

    // Save to Firestore
    await _firestore.collection('tours').doc(tour.id).set(updatedTour.toMap());
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
      if (currentCapacity <= 0) {
        throw Exception("Tour is fully booked.");
      }

      // 3. Decrement Capacity
      transaction.update(tourRef, {
        'maxAttendees': currentCapacity - 1,
      });

      // 4. Create Booking Document
      transaction.set(bookingRef, booking.toMap());
    });
  }
}
