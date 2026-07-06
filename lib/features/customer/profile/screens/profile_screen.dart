import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../../auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fallback to mock user if not logged in
    final user = AuthBloc.currentUser ?? MockData.users[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User general profile header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.phone,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Hạng ${user.memberTier}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Option Items List
            _buildOptionItem(
              context,
              Icons.lock_reset,
              'Thay đổi mật khẩu',
              'Cập nhật mật khẩu bảo mật mới',
              () => context.push('/change-password'),
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              context,
              Icons.location_on_outlined,
              'Chọn lại chi nhánh',
              'Thay đổi chi nhánh cửa hàng phục vụ đặt món',
              () => context.push('/branch-select'),
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              context,
              Icons.receipt_long_outlined,
              'Lịch sử giao dịch',
              'Xem tất cả các hóa đơn nước đã đặt mua',
              () {
                // Show order history dialog
                showDialog(
                  context: context,
                  builder: (context) {
                    return _buildOrderHistoryDialog(context);
                  },
                );
              },
            ),
            const SizedBox(height: 40),

            // Log out Button
            CoffeeButton(
              label: 'ĐĂNG XUẤT TÀI KHOẢN',
              type: CoffeeButtonType.outline,
              onTap: () {
                context.read<AuthBloc>().add(LogoutRequested());
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đăng xuất tài khoản thành công!')),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistoryDialog(BuildContext context) {
    final history = MockData.orderHistory;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Lịch sử đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: history.isEmpty
            ? const Center(child: Text('Không có đơn hàng nào.'))
            : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final order = history[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn: ${order.orderCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.createdAt.toString().substring(0, 16),
                              style: const TextStyle(fontSize: 10, color: Colors.white30),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${order.finalAmount.toInt()}đ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.status == 'COMPLETED' ? 'Hoàn thành' : 'Đang chờ',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: order.status == 'COMPLETED' ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ĐÓNG', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2, // Account Tab is selected
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.white.withOpacity(0.5),
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        if (index == 0) {
          context.go('/menu');
        } else if (index == 1) {
          context.go('/loyalty');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Thực đơn',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: 'Tích điểm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
