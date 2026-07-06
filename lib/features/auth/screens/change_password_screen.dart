import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/coffee_button.dart';
import '../../../core/widgets/coffee_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../bloc/auth_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới phải tối thiểu 6 ký tự!'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận mật khẩu không khớp!'), backgroundColor: AppColors.error),
      );
      return;
    }

    context.read<AuthBloc>().add(
          ChangePasswordRequested(
            oldPassword: oldPass,
            newPassword: newPass,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        } else if (state is AuthInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật mật khẩu mới thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(); // Go back to profile screen
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
              title: const Text('Đổi Mật Khẩu', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cập nhật bảo mật',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.accent,
                                          ),
                                    ),
                                    const SizedBox(height: 24),
                                    CoffeeTextField(
                                      controller: _oldPasswordController,
                                      label: 'Mật khẩu hiện tại',
                                      hint: 'Nhập mật khẩu hiện tại',
                                      prefixIcon: Icons.lock_outline,
                                      isPassword: true,
                                    ),
                                    const SizedBox(height: 16),
                                    CoffeeTextField(
                                      controller: _newPasswordController,
                                      label: 'Mật khẩu mới',
                                      hint: 'Tối thiểu 6 ký tự',
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
                                      label: 'XÁC NHẬN CẬP NHẬT',
                                      onTap: _submit,
                                    ),
                                  ],
                                ),
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
}
