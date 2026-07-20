import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../models/api_response_model.dart';
import '../models/register_request.dart';

class AuthService {
  /// Calls backend endpoint POST /api/register
  static Future<ApiResponseModel<dynamic>> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponseModel.fromJson(body, (json) => json);
      } else {
        String errorMsg = body['message'] ?? 'Đăng ký thất bại (${response.statusCode})';
        return ApiResponseModel(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      return ApiResponseModel(
        success: false,
        message: 'Lỗi kết nối máy chủ: ${e.toString()}',
      );
    }
  }
}
