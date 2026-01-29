import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';

/// Use-case to upload a user's avatar.
///
/// Accepts a local file path and returns the uploaded avatar URL.
class UploadAvatarUseCase {
  final AuthRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<String> call(String filePath) async {
    if (filePath.isEmpty) {
      throw ArgumentError.value(filePath, 'filePath', 'must not be empty');
    }

    return await repository.uploadAvatar(filePath);
  }
}
