import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../../../core/widgets/status_badge.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  MockOrder? _order;
  String _currentStatus = 'PENDING';
  Timer? _statusTimer;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startMockAutoProgress();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _loadOrder() {
    try {
      _order = MockData.orderHistory.firstWhere((o) => o.id == widget.orderId);
      _currentStatus = _order!.status;
    } catch (e) {
      // Fallback to latest mock order
      if (MockData.orderHistory.isNotEmpty) {
        _order = MockData.orderHistory.first;
        _currentStatus = _order!.status;
      }
    }
  }

  void _startMockAutoProgress() {
    // If order is already completed or cancelled, don't auto progress
    if (_currentStatus == 'COMPLETED' || _currentStatus == 'CANCELLED') return;

    // Simulate Barista KDS updates in sequence for presentation/demonstration
    int seconds = 0;
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (seconds == 3) {
        _updateStatus('CONFIRMED');
      } else if (seconds == 7) {
        _updateStatus('BREWING');
      } else if (seconds == 15) {
        _updateStatus('READY');
        timer.cancel(); // Stop timer when ready. User must tap collect to complete.
      }
    });
  }

  void _updateStatus(String status) {
    setState(() {
      _currentStatus = status;
    });
    // Update global order history list for matching POS/KDS screens
    if (_order != null) {
      final index = MockData.orderHistory.indexWhere((o) => o.id == _order!.id);
      if (index >= 0) {
        final updatedOrder = MockOrder(
          id: _order!.id,
          orderCode: _order!.orderCode,
          branchName: _order!.branchName,
          items: _order!.items,
          totalAmount: _order!.totalAmount,
          discountAmount: _order!.discountAmount,
          finalAmount: _order!.finalAmount,
          paymentMethod: _order!.paymentMethod,
          status: status,
          createdAt: _order!.createdAt,
          source: _order!.source,
        );
        MockData.orderHistory[index] = updatedOrder;
        _order = updatedOrder;
      }
    }
  }

  void _collectOrder() {
    _updateStatus('COMPLETED');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cảm ơn bạn đã thưởng thức nước tại CaffeShop!'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Theo dõi đơn hàng')),
        body: const Center(child: Text('Không tìm thấy đơn hàng')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đơn hàng ${_order!.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              'Chi nhánh: ${_order!.branchName.replaceAll('CaffeShop ', '')}',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // WebSocket live connection status dot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LivePulseDot(),
                  const SizedBox(width: 8),
                  Text(
                    'Đang kết nối live updates (Mock WS)',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Animated Timeline Track
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildTimelineStep(
                    'PENDING',
                    'Chờ xác nhận',
                    'Hệ thống đang tiếp nhận đơn hàng của bạn.',
                    ['PENDING', 'CONFIRMED', 'BREWING', 'READY', 'COMPLETED'].contains(_currentStatus),
                  ),
                  _buildTimelineDivider(['CONFIRMED', 'BREWING', 'READY', 'COMPLETED'].contains(_currentStatus)),
                  _buildTimelineStep(
                    'CONFIRMED',
                    'Đã xác nhận',
                    'Cửa hàng đã duyệt đơn và chuẩn bị pha chế.',
                    ['CONFIRMED', 'BREWING', 'READY', 'COMPLETED'].contains(_currentStatus),
                  ),
                  _buildTimelineDivider(['BREWING', 'READY', 'COMPLETED'].contains(_currentStatus)),
                  _buildTimelineStep(
                    'BREWING',
                    'Đang pha chế',
                    'Barista đang chế biến ly nước của bạn.',
                    ['BREWING', 'READY', 'COMPLETED'].contains(_currentStatus),
                  ),
                  _buildTimelineDivider(['READY', 'COMPLETED'].contains(_currentStatus)),
                  _buildTimelineStep(
                    'READY',
                    'Sẵn sàng phục vụ',
                    'Ly nước đã sẵn sàng! Mời bạn nhận nước tại quầy.',
                    ['READY', 'COMPLETED'].contains(_currentStatus),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Order details preview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chi tiết sản phẩm đã đặt:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                      StatusBadge(status: _currentStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._order!.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.product.name} (x${item.quantity})',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            currencyFormat.format(item.totalPrice),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán', style: TextStyle(fontSize: 13, color: Colors.white60)),
                      Text(
                        currencyFormat.format(_order!.finalAmount),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Interactive action buttons
            if (_currentStatus == 'READY')
              CoffeeButton(
                label: 'XÁC NHẬN ĐÃ NHẬN NƯỚC',
                onTap: _collectOrder,
              ),
            if (_currentStatus == 'COMPLETED')
              CoffeeButton(
                label: 'QUAY LẠI THỰC ĐƠN',
                type: CoffeeButtonType.outline,
                onTap: () => context.go('/menu'),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String stepStatus, String title, String description, bool isCompleted) {
    final isActive = _currentStatus == stepStatus;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marker Dot
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.accent
                : AppColors.background,
            border: Border.all(
              color: isCompleted ? AppColors.accent : Colors.white12,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: AppColors.background)
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 16),
        // Text Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCompleted
                      ? (isActive ? AppColors.accent : Colors.white)
                      : Colors.white24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isCompleted) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(left: 11),
      height: 28,
      width: 2,
      color: isCompleted ? AppColors.accent : Colors.white12,
    );
  }
}

// Live connection pulse dot indicator
class LivePulseDot extends StatefulWidget {
  const LivePulseDot({super.key});

  @override
  State<LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<LivePulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.3 + (_controller.value * 0.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.4 * _controller.value),
                blurRadius: 4,
                spreadRadius: 2,
              )
            ],
          ),
        );
      },
    );
  }
}
