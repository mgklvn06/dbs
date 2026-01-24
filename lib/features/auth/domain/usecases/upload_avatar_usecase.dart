import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';
// import 'dart:dio';

class UploadAvatarUseCase {
  final AuthRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<String> call(String filePath) {
    return repository.uploadAvatar(filePath);
  }
}
