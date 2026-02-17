import 'package:dbs/features/auth/domain/entities/user.dart';
import 'dart:typed_data';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String email, String password);
  Future<UserEntity> signInWithGoogle();
  Future<void> logout();
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });
}
