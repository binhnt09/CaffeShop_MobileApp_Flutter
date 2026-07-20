import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String token;
  final String? baseUrl;

  const ChangePasswordScreen({super.key, required this.token, this.baseUrl});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  late String _apiUrl;

  @override
  void initState() {
    super.initState();
    if (widget.baseUrl != null && widget.baseUrl!.isNotEmpty) {
      _apiUrl = widget.baseUrl!;
    } else if (!kIsWeb && Platform.isAndroid) {
      _apiUrl = 'http://10.0.2.2:8080/api';
    } else {
      _apiUrl = 'http://localhost:8080/api';
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu mới và xác nhận mật khẩu không khớp', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/account/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text.trim(),
          'newPassword': _newPasswordController.text.trim(),
        }),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        _showSnackBar('Đổi mật khẩu thành công!', isSuccess: true);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar(body['message'] ?? 'Đổi mật khẩu thất bại', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi hệ thống: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.errorRed
            : isSuccess
                ? AppColors.successGreen
                : AppColors.coffeePrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latteBackground,
      appBar: AppBar(
        title: const Text('Đổi Mật Khẩu'),
        backgroundColor: AppColors.coffeePrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu hiện tại *',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mochaMedium),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                          if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới *',
                          prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.mochaMedium),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureNew,
                        validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng xác nhận mật khẩu mới' : null,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu mới *',
                          prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.mochaMedium),
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coffeePrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _handleChangePassword,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Lưu Mật Khẩu Mới', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
