import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/core/models/curated_trip.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';

/// CRUD service for saved solo travel plans.
///
/// Firestore path: `users/{uid}/solo_plans/{planId}`
/// Static singleton — not registered in GetIt.
class SoloPlanService {
  SoloPlanService._();
  static final SoloPlanService instance = SoloPlanService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    return _firestore.collection('users').doc(uid).collection('solo_plans');
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  Stream<List<SavedPlan>> streamPlans() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedPlan.fromFirestore).toList());
  }

  Future<SavedPlan?> getActivePlan() async {
    final snap = await _col
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SavedPlan.fromFirestore(snap.docs.first);
  }

  /// Returns the saved-or-active plan for the given curated trip, or null.
  /// Used by [CuratedTripDetailScreen] to reflect "already saved" state.
  Future<SavedPlan?> getCuratedPlanByTripId(String curatedTripId) async {
    final snap = await _col
        .where('curatedTripId', isEqualTo: curatedTripId)
        .where('status', whereIn: ['saved', 'active'])
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SavedPlan.fromFirestore(snap.docs.first);
  }

  // ── Create ────────────────────────────────────────────────────────────────────

  Future<SavedPlan> saveCuratedPlan(CuratedTrip trip) async {
    // Dedup: return existing non-completed plan for this trip
    final existing = await _col
        .where('curatedTripId', isEqualTo: trip.id)
        .where('status', whereIn: ['saved', 'active'])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return SavedPlan.fromFirestore(existing.docs.first);
    }

    final days = trip.days.map((d) {
      final stops = d.stops.map((s) => SavedPlanStop(
            name: s.name,
            placeType: s.type,
            estimatedDuration: s.estimatedDuration,
            lat: s.lat,
            lng: s.lng,
          )).toList();
      return SavedPlanDay(dayNumber: d.day, label: d.label, stops: stops);
    }).toList();

    final plan = SavedPlan(
      id: '',
      title: trip.title,
      tagline: trip.tagline,
      type: 'curated',
      curatedTripId: trip.id,
      status: SoloPlanStatus.saved,
      days: days,
      estimatedBudget: trip.budgetRange,
      areas: trip.areas,
      createdAt: DateTime.now(),
    );

    final ref = await _col.add(plan.toMap());
    return _planWithId(plan, ref.id);
  }

  Future<SavedPlan> saveCustomPlan({
    required String title,
    required String tagline,
    required List<SavedPlanDay> days,
    required String estimatedBudget,
    required List<String> areas,
  }) async {
    final plan = SavedPlan(
      id: '',
      title: title,
      tagline: tagline,
      type: 'custom',
      status: SoloPlanStatus.saved,
      days: days,
      estimatedBudget: estimatedBudget,
      areas: areas,
      createdAt: DateTime.now(),
    );

    final ref = await _col.add(plan.toMap());
    return _planWithId(plan, ref.id);
  }

  // ── Update ────────────────────────────────────────────────────────────────────

  Future<void> startTour(String planId) async {
    await _col.doc(planId).update({
      'status': SoloPlanStatus.active.name,
      'startedAt': Timestamp.now(),
    });
  }

  Future<void> markStopCompleted({
    required String planId,
    required int dayIndex,
    required int stopIndex,
    required bool completed,
  }) async {
    final doc = await _col.doc(planId).get();
    final plan = SavedPlan.fromFirestore(doc);
    final updatedDays = List<SavedPlanDay>.from(plan.days);
    updatedDays[dayIndex] = updatedDays[dayIndex].copyWithStop(stopIndex, completed);

    final allDone = updatedDays
        .every((d) => d.stops.every((s) => s.completed));

    await _col.doc(planId).update({
      'days': updatedDays.map((d) => d.toMap()).toList(),
      if (allDone) 'status': SoloPlanStatus.completed.name,
      if (allDone) 'completedAt': Timestamp.now(),
    });
  }

  Future<void> endTour(String planId) async {
    await _col.doc(planId).update({
      'status': SoloPlanStatus.completed.name,
      'completedAt': Timestamp.now(),
    });
  }

  Future<void> resetToSaved(String planId) async {
    await _col.doc(planId).update({
      'status': SoloPlanStatus.saved.name,
    });
  }

  Future<void> deletePlan(String planId) async {
    await _col.doc(planId).delete();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  SavedPlan _planWithId(SavedPlan plan, String id) => SavedPlan(
        id: id,
        title: plan.title,
        tagline: plan.tagline,
        type: plan.type,
        curatedTripId: plan.curatedTripId,
        status: plan.status,
        days: plan.days,
        estimatedBudget: plan.estimatedBudget,
        areas: plan.areas,
        startedAt: plan.startedAt,
        completedAt: plan.completedAt,
        createdAt: plan.createdAt,
      );
}
