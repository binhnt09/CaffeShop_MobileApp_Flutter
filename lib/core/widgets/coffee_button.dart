import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum CoffeeButtonType { primary, secondary, outline }

class CoffeeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final CoffeeButtonType type;
  final IconData? icon;
  final double? width;

  const CoffeeButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.type = CoffeeButtonType.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonWidth = width ?? double.infinity;

    Widget childWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else
          Text(label),
      ],
    );

    if (type == CoffeeButtonType.outline) {
      return SizedBox(
        width: buttonWidth,
        height: 54,
        child: OutlinedButton(
          onPressed: isLoading ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: BorderSide(color: AppColors.accent.withOpacity(0.8), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: childWidget,
        ),
      );
    }

    final gradientColors = type == CoffeeButtonType.primary
        ? [AppColors.primary, AppColors.primaryLight]
        : [AppColors.surfaceVariant, AppColors.surface];

    return Container(
      width: buttonWidth,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: onTap == null ? [Colors.grey.shade800, Colors.grey.shade900] : gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: onTap == null
            ? []
            : [
                BoxShadow(
                  color: (type == CoffeeButtonType.primary ? AppColors.primary : Colors.black).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: childWidget),
        ),
      ),
    );
  }
}
