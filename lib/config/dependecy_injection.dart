import 'package:dbs/features/auth/domain/usecases/google_signin_usecase.dart';
import 'package:dbs/features/auth/domain/usecases/login_user.dart';
import 'package:dbs/features/auth/domain/usecases/logout_user.dart';
import 'package:dbs/features/auth/domain/usecases/register_user.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/datasources/auth_remote_datasource_impl.dart';
import '../features/auth/data/datasources/cloudinary_datasource.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/usecases/upload_avatar_usecase.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Booking
import '../features/booking/data/datasources/booking_remote_datasource.dart';
import '../features/booking/data/repositories/booking_repository_impl.dart';
import '../features/booking/domain/repositories/booking_repository.dart';
import '../features/booking/domain/usecases/book_appointment.dart';
import '../features/booking/domain/usecases/get_appointments_for_user.dart';
import '../features/booking/presentation/bloc/booking_bloc.dart';
// Doctor
import '../features/doctor/data/datasources/doctor_remote_datasource.dart';
import '../features/doctor/data/repositories/doctor_repository_impl.dart';
import '../features/doctor/domain/repositories/doctor_repository.dart';
import '../features/doctor/domain/usecases/get_doctors.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );

  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  sl.registerLazySingleton<GoogleSignIn>(
  () => GoogleSignIn(),
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
  // Booking data layer
  sl.registerLazySingleton<BookingRemoteDataSource>(() => BookingRemoteDataSourceImpl());
  sl.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl(sl()));
  // Doctor
  sl.registerLazySingleton<DoctorRemoteDataSource>(() => DoctorRemoteDataSourceImpl());
  sl.registerLazySingleton<DoctorRepository>(() => DoctorRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDoctors(sl()));
    // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));
  
  // Booking use-cases
  sl.registerLazySingleton(() => BookAppointment(sl()));
  sl.registerLazySingleton(() => GetAppointmentsForUser(sl()));
  // Booking Bloc
  sl.registerFactory(
    () => BookingBloc(
      bookAppointment: sl(),
      getAppointmentsForUser: sl(),
      bookingRepository: sl(),
    ),
  );
    // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      registerUseCase: sl(),
      uploadAvatarUseCase: sl(),
      googleSignInUseCase: sl(),
    ),
  );
}

