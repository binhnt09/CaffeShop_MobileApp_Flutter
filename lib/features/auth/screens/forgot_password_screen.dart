import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/coffee_button.dart';
import '../../../core/widgets/coffee_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int _step = 1; // 1: Enter Email, 2: OTP, 3: New Password
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _submitEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không hợp lệ!'), backgroundColor: AppColors.error),
      );
      return;
    }
    context.read<AuthBloc>().add(ForgotPasswordRequested(email));
  }

  void _submitOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp == '123456') {
      setState(() {
        _step = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã OTP không đúng! Nhập: 123456'), backgroundColor: AppColors.error),
      );
    }
  }

  void _submitNewPassword() {
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu tối thiểu phải 6 ký tự!'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không trùng khớp!'), backgroundColor: AppColors.error),
      );
      return;
    }
    context.read<AuthBloc>().add(ResetPasswordRequested(_newPasswordController.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        } else if (state is AuthOtpSent) {
          setState(() {
            _step = 2;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mã OTP đã gửi qua email! Nhập: ${state.demoOtp}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AuthPasswordResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Khôi phục mật khẩu thành công! Hãy đăng nhập lại.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/login');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (_step == 2) {
                    setState(() {
                      _step = 1;
                    });
                  } else if (_step == 3) {
                    setState(() {
                      _step = 2;
                    });
                  } else {
                    context.pop();
                  }
                },
              ),
            ),
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // Dark coffee theme gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF140F0A),
                        Color(0xFF2C1E14),
                        Color(0xFF140F0A),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Khôi Phục Mật Khẩu',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 24),

                          // Glassmorphism Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                                child: _buildBody(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập địa chỉ Email liên kết với tài khoản của bạn. Chúng tôi sẽ gửi mã xác thực OTP khôi phục.',
            style: TextStyle(color: AppColors.onBackground, height: 1.4),
          ),
          const SizedBox(height: 24),
          CoffeeTextField(
            controller: _emailController,
            label: 'Địa chỉ Email',
            hint: 'Nhập email (vd: customer@coffee.com)',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          CoffeeButton(
            label: 'GỬI MÃ OTP',
            onTap: _submitEmail,
          ),
        ],
      );
    } else if (_step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập mã xác thực gồm 6 chữ số vừa được gửi đến email của bạn.',
            style: TextStyle(color: AppColors.onBackground, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    if (value.length == 1 && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    }
                    if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          CoffeeButton(
            label: 'XÁC THỰC OTP',
            onTap: _submitOtp,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đặt mật khẩu mới cho tài khoản của bạn.',
            style: TextStyle(color: AppColors.onBackground, height: 1.4),
          ),
          const SizedBox(height: 24),
          CoffeeTextField(
            controller: _newPasswordController,
            label: 'Mật khẩu mới',
            hint: 'Nhập mật khẩu mới',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          CoffeeTextField(
            controller: _confirmPasswordController,
            label: 'Xác nhận mật khẩu mới',
            hint: 'Nhập lại mật khẩu mới',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 24),
          CoffeeButton(
            label: 'CẬP NHẬT MẬT KHẨU',
            onTap: _submitNewPassword,
          ),
        ],
      );
    }
  }
}
