import 'package:flutter/material.dart';
import 'package:g2_caffeshop_app/features/auth/screens/login_screen.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const CaffeShopApp());
}

class CaffeShopApp extends StatelessWidget {
  const CaffeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaffeShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.coffeePrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.coffeePrimary,
          primary: AppColors.coffeePrimary,
          secondary: AppColors.warmAmber,
          surface: AppColors.latteBackground,
        ),
        scaffoldBackgroundColor: AppColors.latteBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.coffeePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
