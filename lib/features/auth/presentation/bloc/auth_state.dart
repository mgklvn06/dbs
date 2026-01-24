abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

class AuthUnauthenticated extends AuthState {}