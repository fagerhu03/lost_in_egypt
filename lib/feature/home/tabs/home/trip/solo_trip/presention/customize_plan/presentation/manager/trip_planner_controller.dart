import 'package:flutter/material.dart';
import '../../data/repositories/trip_planner_repository_impl.dart';
import '../../domain/entities/trip_plan_entity.dart';
import '../../domain/usecases/build_trip_prompt_usecase.dart';

class TripPlannerController extends ChangeNotifier {
  TripPlannerController()
      : _buildPromptUseCase =
  BuildTripPromptUseCase(TripPlannerRepositoryImpl());

  final BuildTripPromptUseCase _buildPromptUseCase;

  TripPlanEntity _plan = const TripPlanEntity();
  int _currentPage = 0;

  TripPlanEntity get plan => _plan;
  int get currentPage => _currentPage;

  void setPage(int index) {
    _currentPage = index;
    notifyListeners();
  }

  void updateLocation(String value) {
    _plan = _plan.copyWith(location: value);
    notifyListeners();
  }

  void updateLocationCoords(double lat, double lng) {
    _plan = _plan.copyWith(locationLat: lat, locationLng: lng);
    notifyListeners();
  }

  void updateFromDate(DateTime value) {
    _plan = _plan.copyWith(fromDate: value);
    notifyListeners();
  }

  void updateToDate(DateTime value) {
    _plan = _plan.copyWith(toDate: value);
    notifyListeners();
  }

  void toggleInterest(String value) {
    final updated = List<String>.from(_plan.interests);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    _plan = _plan.copyWith(interests: updated);
    notifyListeners();
  }

  void toggleArea(String value) {
    final updated = List<String>.from(_plan.areas);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    _plan = _plan.copyWith(areas: updated);
    notifyListeners();
  }

  void toggleTripTime(String value) {
    final updated = List<String>.from(_plan.tripTimes);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    _plan = _plan.copyWith(tripTimes: updated);
    notifyListeners();
  }

  void setMinBudget(double value) {
    final newMin = value;
    final newMax = _plan.maxBudget < newMin ? newMin : _plan.maxBudget;
    _plan = _plan.copyWith(minBudget: newMin, maxBudget: newMax);
    notifyListeners();
  }

  void setMaxBudget(double value) {
    final newMax = value < _plan.minBudget ? _plan.minBudget : value;
    _plan = _plan.copyWith(maxBudget: newMax);
    notifyListeners();
  }

  void updateBudgetRange(double min, double max) {
    _plan = _plan.copyWith(minBudget: min, maxBudget: max);
    notifyListeners();
  }

  String buildPrompt() {
    return _buildPromptUseCase(_plan);
  }
}