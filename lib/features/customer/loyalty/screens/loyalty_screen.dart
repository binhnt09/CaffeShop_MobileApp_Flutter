import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../../core/network/api_service.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int _userPoints = 0;
  String _userTier = 'BRONZE';
  String _nextTierName = 'Silver';
  int _pointsToNextTier = 500;
  double _tierProgress = 0.0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _vouchers = [
    {'name': 'Miễn Phí 1 Topping Trân Châu', 'points': 40, 'desc': 'Áp dụng cho mọi ly nước size M/L'},
    {'name': 'Giảm 15.000đ Toàn Đơn', 'points': 80, 'desc': 'Đơn hàng tối thiểu từ 40.000đ'},
    {'name': 'Mua 1 Tặng 1 Thức Uống Bất Kỳ', 'points': 120, 'desc': 'Áp dụng vào ngày hội thành viên thứ Ba'},
    {'name': 'Ly Sứ CaffeShop Phiên Bản Giới Hạn', 'points': 300, 'desc': 'Nhận trực tiếp tại quầy cửa hàng'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }

  List<Map<String, dynamic>> _transactions = [];

  Future<void> _loadTransactions(String token) async {
    try {
      final txns = await ApiService.instance.getLoyaltyTransactions(token);
      if (mounted) {
        setState(() => _transactions = txns);
      }
    } catch (_) {}
  }

  Future<void> _loadLoyaltyData() async {
    final token = AuthBloc.currentUser?.token;
    if (token == null) {
      // Local mock fallback if no login
      setState(() {
        _userPoints = MockData.users[0].loyaltyPoints;
        _userTier = MockData.users[0].memberTier;
        _nextTierName = 'Silver';
        _pointsToNextTier = 500 - _userPoints;
        _tierProgress = _userPoints / 500.0;
        _isLoading = false;
        _transactions = [
          {'transactionType': 'EARN', 'pointsAmount': 35, 'description': 'Cộng điểm đơn hàng CF-1024', 'createdAt': '2026-07-20T10:30:00Z'},
          {'transactionType': 'REDEEM', 'pointsAmount': -40, 'description': 'Đổi Voucher Miễn Phí Topping', 'createdAt': '2026-07-18T14:15:00Z'},
        ];
      });
      return;
    }

    try {
      final loyalty = await ApiService.instance.getMyLoyalty(token);
      await _loadTransactions(token);
      if (loyalty != null && mounted) {
        setState(() {
          _userPoints = loyalty.loyaltyPoints;
          _userTier = loyalty.membershipTier;
          _nextTierName = loyalty.nextTierName ?? 'Silver';
          _pointsToNextTier = loyalty.pointsToNextTier ?? 0;
          _tierProgress = loyalty.tierProgress ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin tích điểm: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _redeemVoucher(Map<String, dynamic> voucher) async {
    final pointsCost = voucher['points'] as int;
    if (_userPoints >= pointsCost) {
      final token = AuthBloc.currentUser?.token;
      if (token != null) {
        setState(() => _isLoading = true);
        final res = await ApiService.instance.redeemPoints(pointsCost, token);
        if (res != null) {
          await _loadLoyaltyData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? 'Đổi quà thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đổi quà thất bại, vui lòng thử lại sau.'), backgroundColor: AppColors.error),
            );
          }
        }
      } else {
        // Mock updates locally
        setState(() {
          _userPoints -= pointsCost;
          _pointsToNextTier = 500 - _userPoints;
          _tierProgress = _userPoints / 500.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đổi quà thành công! Đã đổi: ${voucher['name']}. Vui lòng kiểm tra ví Voucher.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không đủ điểm thưởng để đổi voucher này!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate tier specific gradients
    LinearGradient tierGradient;
    String tierTitle;
    Color tierBorder;
    
    if (_userTier == 'GOLD') {
      tierGradient = const LinearGradient(colors: [Color(0xFFE5A93B), Color(0xFF9E6E17)]);
      tierTitle = 'Thành Viên Vàng (Gold)';
      tierBorder = const Color(0xFFFFD700);
    } else if (_userTier == 'PLATINUM') {
      tierGradient = const LinearGradient(colors: [Color(0xFF8A9EA7), Color(0xFF3F4E56)]);
      tierTitle = 'Thành Viên Bạch Kim (Platinum)';
      tierBorder = Colors.white70;
    } else if (_userTier == 'SILVER') {
      tierGradient = const LinearGradient(colors: [Color(0xFFC0C0C0), Color(0xFF808080)]);
      tierTitle = 'Thành Viên Bạc (Silver)';
      tierBorder = Colors.white30;
    } else {
      tierGradient = const LinearGradient(colors: [Color(0xFF8C6239), Color(0xFF4C3017)]);
      tierTitle = 'Thành Viên Đồng (Bronze)';
      tierBorder = Colors.transparent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành viên & Tích điểm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Membership loyalty Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: tierGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tierBorder.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 28),
                      Text(
                        tierTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('ĐIỂM TÍCH LŨY CỦA BẠN', style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _userPoints.toString(),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text('điểm', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar to next tier
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hiện tại: ${_userTier.toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(_pointsToNextTier > 0 
                          ? 'Cần $_pointsToNextTier điểm để lên $_nextTierName'
                          : 'Đã đạt hạng cao nhất', 
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _tierProgress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Voucher Grid List section
            Text(
              'Đổi Voucher quà tặng:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.accent,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vouchers.length,
              itemBuilder: (context, index) {
                final voucher = _vouchers[index];
                final points = voucher['points'] as int;
                final canRedeem = _userPoints >= points;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      // Points icon box
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (canRedeem ? AppColors.accent : Colors.white12).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$points\nđ',
                            style: TextStyle(
                              color: canRedeem ? AppColors.accent : Colors.white24,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voucher['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voucher['desc'] as String,
                              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action Button
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: canRedeem ? () => _redeemVoucher(voucher) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('ĐỔI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            if (_transactions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Lịch Sử Giao Dịch Điểm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final txn = _transactions[index];
                  final isEarn = (txn['transactionType'] ?? '').toString().toUpperCase() == 'EARN' || (txn['pointsAmount'] ?? 0) > 0;
                  final pts = txn['pointsAmount'] ?? 0;
                  final desc = txn['description'] ?? 'Giao dịch điểm';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                              color: isEarn ? AppColors.success : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(
                                  txn['createdAt'] != null ? txn['createdAt'].toString().substring(0, 10) : '',
                                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${isEarn ? "+" : ""}$pts điểm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isEarn ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1, // Loyalty Tab is selected
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.white.withOpacity(0.5),
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        if (index == 0) {
          context.go('/menu');
        } else if (index == 2) {
          context.push('/profile');
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
