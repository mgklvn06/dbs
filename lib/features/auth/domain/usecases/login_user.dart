import 'package:dbs/features/auth/domain/entities/user.dart';
import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> call(String email, String password) {
    return repository.login(email, password);
  }

  Future<UserEntity> googleLogin() {
    return repository.signInWithGoogle();
  }
}
