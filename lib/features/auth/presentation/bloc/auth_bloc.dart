import 'package:dbs/features/auth/domain/usecases/login_user.dart';
import 'package:dbs/features/auth/domain/usecases/logout_user.dart';
import 'package:dbs/features/auth/domain/usecases/register_user.dart';
// import 'package:dbs/features/auth/presentation/pages/splash_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<RegisterRequested>(_onRegister);
    on<AuthCheckRequested>(_onAuthCheck);

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

  void _onAuthCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      emit(AuthUnauthenticated());
    } else {
      emit(AuthAuthenticated());
    }
  }


}

class AuthCheckRequested implements AuthEvent {
  
}

