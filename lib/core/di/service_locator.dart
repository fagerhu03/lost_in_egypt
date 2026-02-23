import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../feature/auth/data/datasources/auth_remote_datasource.dart';
import '../../feature/auth/data/repository_impl/auth_repository_impl.dart';
import '../../feature/auth/domain/repositories/auth_repository.dart';
import '../../feature/auth/login/bloc/login_bloc.dart';
import '../../feature/home/tabs/map/data/map_repository.dart';
import '../../feature/home/tabs/map/services/navigation_service.dart';
import '../../feature/home/tabs/map/bloc/map_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
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

  // --- Repositories ---
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<MapRepository>(() => MapRepository());
  sl.registerLazySingleton<NavigationService>(() => NavigationService());

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
}
