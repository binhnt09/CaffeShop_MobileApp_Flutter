import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/widgets/coffee_button.dart';
import '../../../core/widgets/coffee_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _quickLogin(MockUser user) {
    _emailController.text = user.email;
    _passwordController.text = '${user.role.toLowerCase()}123';
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(_emailController.text, _passwordController.text),
          );
    }
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
        } else if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chào mừng ${state.user.fullName} quay trở lại!'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Role-based routing
          switch (state.user.role) {
            case 'CUSTOMER':
              context.go('/branch-select');
              break;
            case 'CASHIER':
              context.go('/pos');
              break;
            case 'BARISTA':
              context.go('/kds');
              break;
            case 'MANAGER':
              context.go('/manager/dashboard');
              break;
            case 'ADMIN':
              context.go('/admin/dashboard');
              break;
            default:
              context.go('/login');
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return LoadingOverlay(
          isLoading: isLoading,
          child: Scaffold(
            body: Stack(
              children: [
                // Background coffee image (mocked using a warm dark gradient & blur)
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
                // Decorative circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.08),
                    ),
                  ),
                ),
                // Form Container
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo & Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceVariant,
                              border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1.5),
                            ),
                            child: const Icon(
                              Icons.local_cafe_rounded,
                              size: 48,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'CaffeShop Chain',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          Text(
                            'Hệ Thống Quản Lý Chuỗi Cửa Hàng',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurface.withOpacity(0.5),
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 32),

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
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Đăng Nhập',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: AppColors.accent,
                                              fontSize: 22,
                                            ),
                                      ),
                                      const SizedBox(height: 24),
                                      CoffeeTextField(
                                        controller: _emailController,
                                        label: 'Email / Số điện thoại',
                                        hint: 'Nhập email của bạn (vd: customer@coffee.com)',
                                        prefixIcon: Icons.email_outlined,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Vui lòng điền trường này';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      CoffeeTextField(
                                        controller: _passwordController,
                                        label: 'Mật khẩu',
                                        hint: 'Nhập mật khẩu',
                                        prefixIcon: Icons.lock_outline,
                                        isPassword: true,
                                        validator: (val) {
                                          if (val == null || val.isEmpty) {
                                            return 'Vui lòng điền mật khẩu';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => context.push('/forgot-password'),
                                          child: const Text(
                                            'Quên mật khẩu?',
                                            style: TextStyle(color: AppColors.accent),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      CoffeeButton(
                                        label: 'ĐĂNG NHẬP',
                                        onTap: _submit,
                                        isLoading: isLoading,
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Chưa có tài khoản? ',
                                            style: TextStyle(color: AppColors.onSurface.withOpacity(0.6)),
                                          ),
                                          GestureDetector(
                                            onTap: () => context.push('/register'),
                                            child: const Text(
                                              'Đăng ký ngay',
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
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          // Quick login helper for demonstration/grading
                          Text(
                            'Demo Quick Login (Chọn vai trò để đăng nhập nhanh):',
                            style: TextStyle(
                              color: AppColors.accent.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            alignment: WrapAlignment.center,
                            children: MockData.users.map((user) {
                              IconData icon;
                              switch (user.role) {
                                case 'CUSTOMER':
                                  icon = Icons.shopping_bag_outlined;
                                  break;
                                case 'CASHIER':
                                  icon = Icons.point_of_sale;
                                  break;
                                case 'BARISTA':
                                  icon = Icons.coffee_maker;
                                  break;
                                case 'MANAGER':
                                  icon = Icons.storefront;
                                  break;
                                case 'ADMIN':
                                  icon = Icons.admin_panel_settings_outlined;
                                  break;
                                default:
                                  icon = Icons.person;
                              }
                              return ActionChip(
                                avatar: Icon(icon, size: 16, color: AppColors.background),
                                label: Text(user.role),
                                backgroundColor: AppColors.accent,
                                labelStyle: const TextStyle(
                                  color: AppColors.background,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onPressed: () => _quickLogin(user),
                              );
                            }).toList(),
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
