import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class CloudinaryService {
  static final Dio _dio = Dio();

  static Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
        'upload_preset': 'caffeshop_unsigned',
        'cloud_name': ApiConstants.cloudinaryCloudName,
      });

      final uri = 'https://api.cloudinary.com/v1_1/${ApiConstants.cloudinaryCloudName}/image/upload';
      final response = await _dio.post(uri, data: formData);

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }
      throw Exception('Tải ảnh lên Cloudinary thất bại (Status ${response.statusCode})');
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      rethrow;
    }
  }
}
