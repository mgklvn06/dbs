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

class AvatarUploadSuccess extends AuthState {
  final String avatarUrl;

  const AvatarUploadSuccess(this.avatarUrl);
}

class AuthUnauthenticated extends AuthState {}