import 'package:dbs/features/auth/domain/repositories/auth_repository.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';

/// Use-case to upload a user's avatar.
///
  /// Accepts image bytes or a local file path and returns uploaded URL.
class UploadAvatarUseCase {
  final AuthRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<String> call({
    String? filePath,
    Uint8List? bytes,
    String? fileName,
  }) async {
    Uint8List resolvedBytes;
    String resolvedFileName = fileName ?? 'avatar.jpg';

    if (bytes != null && bytes.isNotEmpty) {
      resolvedBytes = bytes;
    } else if (filePath != null && filePath.isNotEmpty) {
      final xFile = XFile(filePath);
      resolvedBytes = await xFile.readAsBytes();
      if (fileName == null || fileName.trim().isEmpty) {
        final fallback = xFile.name.trim();
        if (fallback.isNotEmpty) {
          resolvedFileName = fallback;
        }
      }
    } else {
      throw ArgumentError('Either bytes or filePath must be provided');
    }

    return await repository.uploadAvatar(
      bytes: resolvedBytes,
      fileName: resolvedFileName,
    );
  }
}
