import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../feature/auth/data/datasources/auth_remote_datasource.dart';
import '../../feature/auth/data/repository_impl/auth_repository_impl.dart';
import '../../feature/auth/domain/repositories/auth_repository.dart';
import '../../feature/auth/presentation/login/bloc/login_bloc.dart';
import '../../feature/home/tabs/map/data/places_api_service.dart';
import '../../feature/home/tabs/map/data/map_repository.dart';
import '../../feature/home/tabs/map/data/datasources/navigation_service.dart';
import '../../feature/home/tabs/map/bloc/map_bloc.dart';

// --- Admin ---
import '../../feature/admin/data/datasources/admin_data_source.dart';
import '../../feature/admin/data/repository_impl/admin_repository_impl.dart';
import '../../feature/admin/domain/repositories/admin_repository.dart';
import '../../feature/admin/domain/usecases/admin_usecases.dart';

// --- Reports ---
import '../../feature/admin/domain/repositories/reports_repository.dart';
import '../../feature/admin/data/repository_impl/reports_repository_impl.dart';

// --- Guide Application ---
import '../../feature/guide_application/data/datasources/guide_application_data_source.dart';
import '../../feature/guide_application/domain/repositories/guide_application_repository.dart';
import '../../feature/guide_application/data/repository_impl/guide_application_repository_impl.dart';
import '../../feature/guide_application/domain/usecases/apply_guide_usecase.dart';

// --- Tours ---
import '../../feature/tours/data/datasources/tours_data_source.dart';
import '../../feature/tours/data/datasources/tours_data_source_impl.dart';
import '../../feature/tours/domain/repositories/tours_repository.dart';
import '../../feature/tours/data/repositories/tours_repository_impl.dart';
import '../../feature/tours/domain/usecases/create_tour_usecase.dart';
import '../../feature/tours/domain/usecases/get_all_tours_usecase.dart';
import '../../feature/tours/domain/usecases/get_guide_tours_usecase.dart';
import '../../feature/tours/domain/usecases/book_tour_usecase.dart';
import '../../feature/tours/presentation/bloc/explorer_tours_cubit.dart';

// --- Notifications ---
import '../../feature/home/notification/data/datasources/notifications_data_source.dart';
import '../../feature/home/notification/domain/repositories/notifications_repository.dart';
import '../../feature/home/notification/data/repositories/notifications_repository_impl.dart';

// --- Reviews ---
import '../../feature/reviews/data/datasources/reviews_data_source.dart';
import '../../feature/reviews/domain/repositories/reviews_repository.dart';
import '../../feature/reviews/data/repositories/reviews_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Maps APIs require client-side keys.
  // Reverted to .env temporarily for development speed.
  final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';

  // --- External ---
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // --- Data Sources ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );

  // --- Places API ---
  sl.registerLazySingleton<PlacesApiService>(
    () => PlacesApiService(apiKey: apiKey),
  );

  // --- Repositories ---
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<MapRepository>(
    () => MapRepository(
      placesApiService: sl(),
      apiKey: apiKey,
    ),
  );
  sl.registerLazySingleton<NavigationService>(() => NavigationService());

  // --- Guide Application Deps ---
  sl.registerLazySingleton<GuideApplicationDataSource>(() => GuideApplicationDataSourceImpl());
  sl.registerLazySingleton<GuideApplicationRepository>(() => GuideApplicationRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(() => ApplyGuideUseCase(sl()));

  // --- Admin Deps ---
  sl.registerLazySingleton<AdminDataSource>(() => AdminDataSourceImpl());
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(() => GetPendingGuidesUseCase(sl()));
  sl.registerLazySingleton(() => ApproveGuideUseCase(sl()));
  sl.registerLazySingleton(() => RejectGuideUseCase(sl()));

  // --- Reports Deps ---
  sl.registerLazySingleton<ReportsRepository>(() => ReportsRepositoryImpl());

  // --- Tours Deps ---
  sl.registerLazySingleton<ToursDataSource>(() => ToursDataSourceImpl());
  sl.registerLazySingleton<ToursRepository>(() => ToursRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton(() => CreateTourUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetAllToursUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetGuideToursUseCase(repository: sl()));
  sl.registerLazySingleton(() => BookTourUseCase(repository: sl()));

  // --- Notifications Deps ---
  sl.registerLazySingleton<NotificationsDataSource>(() => NotificationsDataSourceImpl());
  sl.registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(dataSource: sl()));

  // --- Reviews Deps ---
  sl.registerLazySingleton<ReviewsDataSource>(() => ReviewsDataSourceImpl());
  sl.registerLazySingleton<ReviewsRepository>(() => ReviewsRepositoryImpl(dataSource: sl()));

  // --- BLoCs ---
  sl.registerFactory<LoginBloc>(
    () => LoginBloc(authRepository: sl()),
  );

  sl.registerFactory<MapBloc>(
    () => MapBloc(
      mapRepository: sl(),
      navigationService: sl(),
    ),
  );

  sl.registerFactory<ExplorerToursCubit>(
    () => ExplorerToursCubit(getAllToursUseCase: sl()),
  );
}

