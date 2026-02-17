// import 'package:dartz/dartz.dart';
// import 'package:dbs/core/errors/failures.dart';
// import 'package:dbs/features/auth/data/models/user_models.dart';
// import 'package:dbs/features/auth/domain/entities/user.dart';
// import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';
import 'package:dbs/features/auth/domain/usecases/google_signin_usecase.dart';
import 'package:dbs/features/auth/domain/usecases/login_user.dart';
import 'package:dbs/features/auth/domain/usecases/logout_user.dart';
import 'package:dbs/features/auth/domain/usecases/register_user.dart';
import 'package:dbs/features/auth/domain/usecases/upload_avatar_usecase.dart';
// import 'package:dbs/features/auth/presentation/pages/splash_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final GoogleSignInUseCase googleSignInUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
    required this.uploadAvatarUseCase,
    required this.googleSignInUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<RegisterRequested>(_onRegister);
    on<AuthCheckRequested>(_onAuthCheck);
    on<UploadAvatarRequested>(_onUploadAvatar);
    on<GoogleLoginRequested>(_onGoogleLogin);

  }

  Future<void> _onLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await loginUseCase(
        event.email,
        event.password,
      );
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }



  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await logoutUseCase();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await registerUseCase(
        event.email,
        event.password,
      );
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthLoading());
    return FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (user == null) {
        emit(AuthUnauthenticated());
      } else {
        emit(AuthAuthenticated());
      }
    }).catchError((e) {
      emit(AuthError(e.toString()));
    });
  }

  Future<void> _onUploadAvatar(
    UploadAvatarRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final avatarUrl = await uploadAvatarUseCase(filePath: event.filePath);
      emit(AvatarUploadSuccess(avatarUrl));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

 Future<void> _onGoogleLogin(
  GoogleLoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await googleSignInUseCase();

  result.fold(
    (failure) {
      emit(AuthError(failure.message));
    },
    (user) {
      emit(AuthAuthenticated());
    },
  );
}
}
