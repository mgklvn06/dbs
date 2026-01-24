import '../models/user_models.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);

  Future<UserModel> register(String email, String password);

  Future<UserModel> signInWithGoogle();

  Future<void> logout();
}
