import 'package:dbs/features/auth/domain/usecases/login_user.dart';
import 'package:dbs/features/auth/domain/usecases/logout_user.dart';
import 'package:dbs/features/auth/domain/usecases/register_user.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/datasources/auth_remote_datasource_impl.dart';
import '../features/auth/data/datasources/cloudinary_datasource.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/usecases/google_signin_usecase.dart';
import '../features/auth/domain/usecases/upload_avatar_usecase.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';


final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );

  sl.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn.standard(),
  );

  sl.registerLazySingleton<Dio>(
    () => Dio(),
  );

    // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
    ),
  );

  sl.registerLazySingleton<CloudinaryDataSource>(
    () => CloudinaryDataSourceImpl(sl()),
  );
    // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
    // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));
    // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      googleSignInUseCase: sl(),
      logoutUseCase: sl(),
      registerUseCase: sl(),
    ),
  );
}

