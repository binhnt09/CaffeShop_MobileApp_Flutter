import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';

import '../../../../core/network/api_service.dart';
import '../../../auth/bloc/auth_bloc.dart';

class POSHistoryScreen extends StatefulWidget {
  const POSHistoryScreen({super.key});

  @override
  State<POSHistoryScreen> createState() => _POSHistoryScreenState();
}

class _POSHistoryScreenState extends State<POSHistoryScreen> {
  String _paymentFilter = 'ALL'; // ALL, CASH, QR, VNPAY, MOMO
  List<MockOrder> _orders = MockData.orderHistory;
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    final token = AuthBloc.currentUser?.token;
    final branchId = AuthBloc.currentUser?.branchId ?? '1';
    if (token == null) {
      setState(() {
        _orders = MockData.orderHistory;
        _isLoading = false;
      });
      return;
    }
    try {
      final orders = await ApiService.instance.getBranchOrders(branchId, token);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _orders = MockData.orderHistory;
          _isLoading = false;
        });
      }
    }
  }

  List<MockOrder> _getFilteredOrders() {
    // Show only POS and Mobile orders related to current cashier branch
    if (_paymentFilter == 'ALL') return _orders;
    if (_paymentFilter == 'CASH') return _orders.where((o) => o.paymentMethod == 'CASH').toList();
    // QR filters Momo/Vnpay/PayOS
    return _orders.where((o) => o.paymentMethod == 'MOMO' || o.paymentMethod == 'VNPAY' || o.paymentMethod == 'PAYOS' || o.paymentMethod == 'QR').toList();
  }

  void _voidOrder(MockOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Hủy Hóa Đơn Phục Vụ?'),
          content: Text(
            'Bạn có chắc chắn muốn hủy đơn hàng ${order.orderCode}?\nTổng số tiền hoàn: ${currencyFormat.format(order.finalAmount)}',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('HỦY BỎ', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = MockData.orderHistory.indexWhere((o) => o.id == order.id);
                  if (index >= 0) {
                    final cancelledOrder = MockOrder(
                      id: order.id,
                      orderCode: order.orderCode,
                      branchName: order.branchName,
                      items: order.items,
                      totalAmount: order.totalAmount,
                      discountAmount: order.discountAmount,
                      finalAmount: order.finalAmount,
                      paymentMethod: order.paymentMethod,
                      status: 'CANCELLED',
                      createdAt: order.createdAt,
                      source: order.source,
                    );
                    MockData.orderHistory[index] = cancelledOrder;
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã hủy hóa đơn ${order.orderCode} & hoàn tiền thành công!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('XÁC NHẬN HỦY'),
            ),
          ],
        );
      },
    );
  }

  void _reprintReceipt(MockOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang in lại hóa đơn ${order.orderCode} qua máy in Bluetooth...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Quay lại POS',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/pos/counter');
            }
          },
        ),
        title: const Text('Lịch Sử Hóa Đơn Tại Quầy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _paymentFilter == 'ALL',
                  onSelected: (selected) {
                    if (selected) setState(() => _paymentFilter = 'ALL');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Tiền mặt'),
                  selected: _paymentFilter == 'CASH',
                  onSelected: (selected) {
                    if (selected) setState(() => _paymentFilter = 'CASH');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Quét mã QR'),
                  selected: _paymentFilter == 'QR',
                  onSelected: (selected) {
                    if (selected) setState(() => _paymentFilter = 'QR');
                  },
                ),
              ],
            ),
          ),

          // Order list
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy giao dịch nào',
                      style: TextStyle(color: Colors.white.withOpacity(0.3)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final isCancelled = order.status == 'CANCELLED';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCancelled ? AppColors.error.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                            width: isCancelled ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      order.orderCode,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCancelled ? AppColors.error : AppColors.accent,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (order.source == 'POS' ? Colors.blue : Colors.orange).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        order.source == 'POS' ? 'Bán tại quầy' : 'Khách đặt App',
                                        style: TextStyle(
                                          color: order.source == 'POS' ? Colors.blue : Colors.orange,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  order.createdAt.toString().substring(11, 16),
                                  style: const TextStyle(color: Colors.white30, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Items list
                            ...order.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  '• ${item.product.name} (x${item.quantity}) Size ${item.size}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              );
                            }),
                            const Divider(),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tổng tiền: ${currencyFormat.format(order.finalAmount)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Thanh toán: ${order.paymentMethod}',
                                      style: const TextStyle(fontSize: 10, color: Colors.white38),
                                    ),
                                  ],
                                ),
                                // Void or reprint actions
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.print, size: 20, color: Colors.white60),
                                      onPressed: () => _reprintReceipt(order),
                                      tooltip: 'In lại hóa đơn',
                                    ),
                                    if (!isCancelled) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, size: 20, color: AppColors.error),
                                        onPressed: () => _voidOrder(order),
                                        tooltip: 'Hủy hóa đơn',
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Đã hủy đơn',
                                        style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
