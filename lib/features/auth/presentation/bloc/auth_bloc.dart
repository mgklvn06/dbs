import 'package:dbs/features/auth/domain/usecases/login_user.dart';
import 'package:dbs/features/auth/domain/usecases/logout_user.dart';
import 'package:dbs/features/auth/domain/usecases/register_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/google_signin_usecase.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.googleSignInUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<GoogleLoginRequested>(_onGoogleLogin);
    on<LogoutRequested>(_onLogout);
    on<RegisterRequested>(_onRegister);
  }

  Future<void> _onLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      event.email,
      event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (_) => emit(AuthAuthenticated()),
    );
  }

  Future<void> _onGoogleLogin(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await googleSignInUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (_) => emit(AuthAuthenticated()),
    );
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase();
    emit(AuthInitial());
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await registerUseCase(
      event.email,
      event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.toString())),
      (_) => emit(AuthAuthenticated()),
    );
  }
}
