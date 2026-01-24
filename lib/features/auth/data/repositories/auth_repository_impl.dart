import 'dart:io';
import 'package:dbs/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dbs/features/auth/data/datasources/cloudinary_datasource.dart';
import 'package:dbs/features/auth/domain/entities/user.dart';
import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemote;
  final CloudinaryDataSource cloudinaryRemote;

  AuthRepositoryImpl(this.authRemote, this.cloudinaryRemote);

  @override
  Future<UserEntity> login(String email, String password) {
    return authRemote.login(email, password);
  }

  @override
  Future<UserEntity> register(String email, String password) {
    return authRemote.register(email, password);
  }

  @override
  Future<UserEntity> signInWithGoogle() {
    return authRemote.signInWithGoogle();
  }

  @override
  Future<String> uploadAvatar(String filePath) {
    final file = File(filePath);
    return cloudinaryRemote.uploadAvatar(file);
  }

  @override
  Future<void> logout() {
    return authRemote.logout();
  }
}
