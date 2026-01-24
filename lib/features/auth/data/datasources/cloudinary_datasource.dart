import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../config/env.dart';

abstract class CloudinaryDataSource {
  Future<String> uploadAvatar(File image);
}

class CloudinaryDataSourceImpl implements CloudinaryDataSource {
  final Dio dio;

  CloudinaryDataSourceImpl(this.dio);

  @override
  Future<String> uploadAvatar(File image) async {
    final response = await dio.post(
      'https://api.cloudinary.com/v1_1/${Env.cloudinaryCloudName}/image/upload',
      data: FormData.fromMap({
        'upload_preset': Env.cloudinaryUploadPreset,
        'file': await MultipartFile.fromFile(image.path),
      }),
    );

    return response.data['secure_url'];
  }
}
