import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'home_state.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/get_popular_places_usecase.dart';
import '../../domain/usecases/get_popular_tours_stream_usecase.dart';
import '../../data/datasources/serp_api_service.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final GetPopularPlacesUseCase _getPopularPlacesUseCase;
  final GetPopularToursStreamUseCase _getPopularToursStreamUseCase;

  HomeCubit({
    required GetUserProfileUseCase getUserProfileUseCase,
    required GetPopularPlacesUseCase getPopularPlacesUseCase,
    required GetPopularToursStreamUseCase getPopularToursStreamUseCase,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        _getPopularPlacesUseCase = getPopularPlacesUseCase,
        _getPopularToursStreamUseCase = getPopularToursStreamUseCase,
        super(const HomeInitial());

  Future<void> loadHomeData() async {
    emit(const HomeLoading());

    // 1. Fetch user profile
    final profileResult = await _getUserProfileUseCase();
    final user = profileResult.fold(
      (failure) => null,
      (userEntity) => userEntity,
    );

    // 2. Fetch popular places
    final placesResult = await _getPopularPlacesUseCase(10);
    final popularPlaces = placesResult.fold(
      (failure) => [],
      (places) => places,
    );

    // 3. Get events — try fetching fresh from API, fall back to local cache
    final serpApi = SerpApiService();
    Future<List<EventModel>> eventsFuture = serpApi.fetchEvents().catchError((e) {
      debugPrint('Live fetch failed, loading cache: $e');
      return serpApi.getLocalEvents();
    });
    
    final popularToursStream = _getPopularToursStreamUseCase(5);

    emit(HomeLoaded(
      user: user,
      popularPlaces: popularPlaces as List<PlaceModel>,
      eventsFuture: eventsFuture,
      popularToursStream: popularToursStream,
    ));
  }

  Future<void> signOut() async {
    // Note: We use FirebaseAuth directly here since it's a simple global action,
    // but in a more complex setup we'd call an AuthCubit or AuthRepository.
    await FirebaseAuth.instance.signOut();
  }
}
