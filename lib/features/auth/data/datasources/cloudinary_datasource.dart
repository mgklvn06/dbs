import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../config/cloudinary_config.dart';

abstract class CloudinaryDataSource {
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });
}

class CloudinaryDataSourceImpl implements CloudinaryDataSource {
  final Dio dio;

  CloudinaryDataSourceImpl(this.dio);

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final response = await dio.post(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      data: FormData.fromMap({
        'upload_preset': CloudinaryConfig.uploadPreset,
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
    );

    return response.data['secure_url'];
  }
}
