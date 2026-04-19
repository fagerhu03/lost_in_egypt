import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/tour_entity.dart';
import '../../domain/usecases/create_tour_usecase.dart';
import '../../domain/usecases/update_tour_usecase.dart';
import 'create_tour_state.dart';

class CreateTourCubit extends Cubit<CreateTourState> {
  final CreateTourUseCase createTourUseCase;
  final UpdateTourUseCase updateTourUseCase;
  final Uuid _uuid = const Uuid();

  CreateTourCubit({
    required this.createTourUseCase,
    required this.updateTourUseCase,
  }) : super(CreateTourInitial());

  Future<void> submitTour({
    required String title,
    required String description,
    required List<String> destinations,
    required double price,
    required double meetingLatitude,
    required double meetingLongitude,
    required DateTime meetingTime,
    required String frequency,
    required String meetingLocationName,
    required List<File> imageFiles,
    required int maxAttendees,
    String recurrenceType = 'one_time',
    List<int> recurrenceDays = const [],
    String meetingTimeOfDay = '',
    DateTime? nextOccurrence,
  }) async {
    if (title.trim().isEmpty) {
      emit(const CreateTourError("Tour title cannot be empty."));
      return;
    }
    if (price <= 0) {
      emit(const CreateTourError("Price must be greater than zero."));
      return;
    }
    if (maxAttendees <= 0) {
      emit(const CreateTourError("Max attendees must be at least 1."));
      return;
    }
    if (recurrenceType == 'one_time' && meetingTime.isBefore(DateTime.now())) {
      emit(const CreateTourError("Meeting time must be in the future."));
      return;
    }
    if (imageFiles.isEmpty) {
      emit(const CreateTourError("Please add at least one photo of the tour."));
      return;
    }

    emit(CreateTourLoading());

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(const CreateTourError("You must be logged in to create a tour."));
      return;
    }

    final newTourId = _uuid.v4();

    final tourEntity = TourEntity(
      id: newTourId,
      guideId: user.uid,
      title: title,
      description: description,
      destinations: destinations,
      price: price,
      meetingLatitude: meetingLatitude,
      meetingLongitude: meetingLongitude,
      meetingTime: meetingTime,
      frequency: frequency,
      meetingLocationName: meetingLocationName,
      images: const [], // will be populated by DataSource
      maxAttendees: maxAttendees,
      createdAt: DateTime.now(),
      rating: 0.0,
      reviewCount: 0,
      totalCapacity: maxAttendees,
      recurrenceType: recurrenceType,
      recurrenceDays: recurrenceDays,
      meetingTimeOfDay: meetingTimeOfDay,
      nextOccurrence: nextOccurrence,
      isArchived: false,
    );

    final params = CreateTourParams(tour: tourEntity, imageFiles: imageFiles);
    final result = await createTourUseCase(params);

    result.fold(
      (failure) => emit(CreateTourError(failure.message)),
      (_) => emit(CreateTourSuccess()),
    );
  }

  Future<void> updateTour({
    required String tourId,
    required String title,
    required String description,
    required List<String> destinations,
    required double price,
    required double meetingLatitude,
    required double meetingLongitude,
    required DateTime meetingTime,
    required String frequency,
    required String meetingLocationName,
    required List<File> imageFiles,
    required List<String> oldImages,
    required int maxAttendees,
    String recurrenceType = 'one_time',
    List<int> recurrenceDays = const [],
    String meetingTimeOfDay = '',
    DateTime? nextOccurrence,
    int totalCapacity = 0,
  }) async {
    emit(CreateTourLoading());

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(const CreateTourError("You must be logged in to update a tour."));
      return;
    }

    final tourEntity = TourEntity(
      id: tourId,
      guideId: user.uid,
      title: title,
      description: description,
      destinations: destinations,
      price: price,
      meetingLatitude: meetingLatitude,
      meetingLongitude: meetingLongitude,
      meetingTime: meetingTime,
      frequency: frequency,
      meetingLocationName: meetingLocationName,
      images: oldImages,
      maxAttendees: maxAttendees,
      createdAt: DateTime.now(), // updateTour actually preserves this locally though DB has real one, but it's ok for updating other fields
      rating: 0.0,
      reviewCount: 0,
      totalCapacity: totalCapacity > 0 ? totalCapacity : maxAttendees,
      recurrenceType: recurrenceType,
      recurrenceDays: recurrenceDays,
      meetingTimeOfDay: meetingTimeOfDay,
      nextOccurrence: nextOccurrence,
      isArchived: false,
    );

    final params = UpdateTourParams(tour: tourEntity, newImageFiles: imageFiles);
    final result = await updateTourUseCase(params);

    result.fold(
      (failure) => emit(CreateTourError(failure.message)),
      (_) => emit(CreateTourSuccess()),
    );
  }
}
