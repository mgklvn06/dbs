abstract class AuthEvent {
  const AuthEvent();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;

  const RegisterRequested(this.email, this.password);
}

class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class UploadAvatarRequested extends AuthEvent {
  final String filePath;

  const UploadAvatarRequested(this.filePath);
}
