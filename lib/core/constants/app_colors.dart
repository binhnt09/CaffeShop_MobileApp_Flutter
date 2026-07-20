import 'package:flutter/material.dart';

class AppColors {
  // Primary Coffee Palette
  static const Color espressoDark = Color(0xFF2C1A14);
  static const Color coffeePrimary = Color(0xFF5D4037);
  static const Color mochaMedium = Color(0xFF8D6E63);
  static const Color warmAmber = Color(0xFFD7CCC8);
  static const Color latteBackground = Color(0xFFFAF6F0);

  // Accents & Buttons
  static const Color accentOrange = Color(0xFFE65100);
  static const Color buttonPrimary = Color(0xFF6F4E37);
  static const Color buttonHover = Color(0xFF4E342E);

  // Status & Feedback
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningAmber = Color(0xFFF57C00);

  // Text Colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMuted = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);

  // Input & Card Styles
  static const Color inputFill = Color(0xFFF5EFEB);
  static const Color inputBorder = Color(0xFFD7CCC8);
  static const Color cardShadow = Color(0x1A000000);

  // Coffee Gradient
  static const LinearGradient coffeeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3E2723),
      Color(0xFF5D4037),
      Color(0xFF8D6E63),
    ],
  );
}
