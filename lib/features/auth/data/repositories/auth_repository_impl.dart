import 'dart:io';
import 'package:dbs/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dbs/features/auth/data/datasources/cloudinary_datasource.dart';
import 'package:dbs/features/auth/data/models/user_models.dart';
import 'package:dbs/features/auth/domain/entities/user.dart';
import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemote;
  final CloudinaryDataSource cloudinaryRemote;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
  Future<UserEntity> signInWithGoogle() async {
    // Use Firebase Auth's unified approach for both web and mobile
    return await authRemote.signInWithGoogle();
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
