import 'dart:async';
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // Step 1: Info Form, Step 2: OTP
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _countdownTimer;
  String? _sentOtpMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  void _submitInfo() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu xác nhận không khớp!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      context.read<AuthBloc>().add(
            RegisterRequested(
              fullName: _fullNameController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  void _submitOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ mã OTP gồm 6 chữ số!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(OtpSubmitted(otp));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is AuthOtpSent) {
          setState(() {
            _currentStep = 2;
            _sentOtpMessage = 'Mã OTP demo đã gửi qua email: ${state.email}. Nhập: ${state.demoOtp}';
          });
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mã OTP demo gửi thành công: ${state.demoOtp}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (state is AuthOtpSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực OTP thành công! Đang tạo tài khoản...'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AuthAuthenticated) {
          context.go('/branch-select');
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
                  if (_currentStep == 2) {
                    setState(() {
                      _currentStep = 1;
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
                // Background dark coffee gradient
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo / Title
                          Text(
                            'CaffeShop Chain',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStep == 1 ? 'Đăng ký tài khoản khách hàng mới' : 'Xác thực OTP đăng ký',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurface.withOpacity(0.5),
                                ),
                          ),
                          const SizedBox(height: 24),

                          // Step indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepIndicator(1, 'Thông tin', _currentStep >= 1),
                              Container(
                                width: 50,
                                height: 2,
                                color: _currentStep == 2 ? AppColors.accent : Colors.white12,
                              ),
                              _buildStepIndicator(2, 'Xác thực', _currentStep == 2),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Form Glassmorphism Card
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
                                child: _currentStep == 1 ? _buildInfoForm() : _buildOtpForm(),
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

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.accent : AppColors.surface,
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? AppColors.background : AppColors.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.accent : AppColors.onSurface.withOpacity(0.4),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tạo tài khoản',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 24),
          CoffeeTextField(
            controller: _fullNameController,
            label: 'Họ và tên',
            hint: 'Nhập họ tên của bạn',
            prefixIcon: Icons.person_outline,
            validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 16),
          CoffeeTextField(
            controller: _emailController,
            label: 'Địa chỉ Email',
            hint: 'Nhập email (vd: customer@coffee.com)',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Vui lòng nhập email';
              if (!val.contains('@')) return 'Email không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CoffeeTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
          ),
          const SizedBox(height: 16),
          CoffeeTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            hint: 'Tối thiểu 6 ký tự',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
              if (val.length < 6) return 'Mật khẩu tối thiểu phải 6 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CoffeeTextField(
            controller: _confirmPasswordController,
            label: 'Xác nhận mật khẩu',
            hint: 'Nhập lại mật khẩu ở trên',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập lại mật khẩu' : null,
          ),
          const SizedBox(height: 24),
          CoffeeButton(
            label: 'TIẾP TỤC',
            onTap: _submitInfo,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đã có tài khoản? ',
                style: TextStyle(color: AppColors.onSurface.withOpacity(0.6)),
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập mã xác thực OTP',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: 12),
        if (_sentOtpMessage != null)
          Text(
            _sentOtpMessage!,
            style: const TextStyle(color: AppColors.success, fontSize: 13),
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
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
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
          label: 'XÁC NHẬN OTP',
          onTap: _submitOtp,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _resendCountdown > 0
                  ? 'Gửi lại OTP sau ${_resendCountdown}s'
                  : 'Không nhận được mã? ',
              style: TextStyle(color: AppColors.onSurface.withOpacity(0.6), fontSize: 13),
            ),
            if (_resendCountdown == 0)
              GestureDetector(
                onTap: () {
                  context.read<AuthBloc>().add(
                        RegisterRequested(
                          fullName: _fullNameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          password: _passwordController.text,
                        ),
                      );
                },
                child: const Text(
                  'Gửi lại ngay',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
