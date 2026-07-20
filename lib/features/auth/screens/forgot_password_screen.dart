import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? baseUrl;

  const ForgotPasswordScreen({super.key, this.baseUrl});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isStepOne = true;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  String _generatedOtp = '';
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
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleInitReset() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/account/reset-password/init'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _emailController.text.trim()}),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final otp = body['data']?['otpCode'] ?? '123456';
        setState(() {
          _generatedOtp = otp;
          _isStepOne = false;
        });
        _showSnackBar('Mã xác thực OTP mẫu của bạn là: $otp', isSuccess: true);
      } else {
        _showSnackBar(body['message'] ?? 'Không tìm thấy tài khoản', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối máy chủ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFinishReset() async {
    if (!_resetFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/account/reset-password/finish'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'key': _emailController.text.trim(),
          'newPassword': _newPasswordController.text.trim(),
        }),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        _showSnackBar('Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.', isSuccess: true);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar(body['message'] ?? 'Đặt lại mật khẩu thất bại', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: $e', isError: true);
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
        title: const Text('Khôi Phục Mật Khẩu'),
        backgroundColor: AppColors.coffeePrimary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _isStepOne ? _buildStepOneForm() : _buildStepTwoForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepOneForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_reset, color: AppColors.coffeePrimary, size: 28),
              SizedBox(width: 10),
              Text('Quên Mật Khẩu',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espressoDark)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập email đã đăng ký của bạn để nhận mã OTP khôi phục mật khẩu.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập Email';
              if (!val.contains('@')) return 'Email không hợp lệ';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Địa chỉ Email *',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.mochaMedium),
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
              onPressed: _isLoading ? null : _handleInitReset,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Gửi mã OTP xác nhận', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwoForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.mark_email_read, color: AppColors.successGreen, size: 28),
              SizedBox(width: 10),
              Text('Nhập Mã Xác Thực & Mật Khẩu',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espressoDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mã OTP đã được gửi tới email ${_emailController.text}. (Mã mẫu: $_generatedOtp)',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập mã OTP' : null,
            decoration: InputDecoration(
              labelText: 'Mã OTP (6 chữ số) *',
              prefixIcon: const Icon(Icons.pin, color: AppColors.mochaMedium),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mật khẩu mới';
              if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới *',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mochaMedium),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureNewPassword,
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng xác nhận mật khẩu' : null,
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
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleFinishReset,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Xác nhận Đổi Mật Khẩu', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
