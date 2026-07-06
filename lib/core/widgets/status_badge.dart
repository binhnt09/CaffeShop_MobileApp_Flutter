import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'PENDING':
        backgroundColor = AppColors.info.withOpacity(0.15);
        textColor = AppColors.info;
        label = 'Chờ duyệt';
        break;
      case 'CONFIRMED':
        backgroundColor = AppColors.primaryLight.withOpacity(0.15);
        textColor = AppColors.primaryLight;
        label = 'Đã nhận đơn';
        break;
      case 'BREWING':
        backgroundColor = AppColors.warning.withOpacity(0.15);
        textColor = AppColors.warning;
        label = 'Đang pha chế';
        break;
      case 'READY':
        backgroundColor = AppColors.success.withOpacity(0.15);
        textColor = AppColors.success;
        label = 'Sẵn sàng';
        break;
      case 'COMPLETED':
        backgroundColor = AppColors.success.withOpacity(0.25);
        textColor = AppColors.success;
        label = 'Hoàn thành';
        break;
      case 'CANCELLED':
        backgroundColor = AppColors.error.withOpacity(0.15);
        textColor = AppColors.error;
        label = 'Đã hủy';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
