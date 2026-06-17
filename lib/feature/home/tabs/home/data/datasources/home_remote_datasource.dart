import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'serp_api_service.dart';

abstract class HomeRemoteDataSource {
  Future<Map<String, dynamic>> getUserProfile(String uid);
  Stream<QuerySnapshot> getEventsStream(int limit);
  Stream<QuerySnapshot> getPopularToursStream(int limit);
  Future<void> syncLiveEvents();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirebaseFirestore firestore;

  HomeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found');
    }
    return doc.data()!;
  }

  @override
  Stream<QuerySnapshot> getEventsStream(int limit) {
    return firestore.collection('events').limit(limit).snapshots();
  }

  @override
  Stream<QuerySnapshot> getPopularToursStream(int limit) {
    return firestore
        .collection('tours')
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots();
  }
  @override
  Future<void> syncLiveEvents() async {
    try {
      final serpApi = SerpApiService();
      final events = await serpApi.fetchEvents();
      
      final batch = firestore.batch();
      final eventsRef = firestore.collection('events');
      
      for (final event in events) {
        final docRef = eventsRef.doc(event.id);
        batch.set(docRef, event.toMap(), SetOptions(merge: true));
      }
      
      await batch.commit();
      debugPrint('Synced ${events.length} events from SerpApi to Firestore.');
    } catch (e) {
      debugPrint('Failed to sync events: $e');
    }
  }
}
