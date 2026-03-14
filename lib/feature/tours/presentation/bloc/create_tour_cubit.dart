import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/tour_entity.dart';
import '../../domain/usecases/create_tour_usecase.dart';
import 'create_tour_state.dart';

class CreateTourCubit extends Cubit<CreateTourState> {
  final CreateTourUseCase createTourUseCase;
  final Uuid _uuid = const Uuid();

  CreateTourCubit({required this.createTourUseCase}) : super(CreateTourInitial());

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
  }) async {
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
    );

    final params = CreateTourParams(tour: tourEntity, imageFiles: imageFiles);
    final result = await createTourUseCase(params);

    result.fold(
      (failure) => emit(CreateTourError(failure.message)),
      (_) => emit(CreateTourSuccess()),
    );
  }
}
