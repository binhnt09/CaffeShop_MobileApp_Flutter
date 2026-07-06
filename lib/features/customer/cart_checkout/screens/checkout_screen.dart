import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../bloc/cart_bloc.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'CASH'; // CASH, MOMO, VNPAY
  final _notesController = TextEditingController();
  bool _isProcessing = false;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitOrder(CartState cartState) async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate Payment Provider processing
    if (_paymentMethod == 'MOMO') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang mở ứng dụng MoMo và xử lý giao dịch...'), backgroundColor: Colors.purple),
      );
    } else if (_paymentMethod == 'VNPAY') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang kết nối cổng thanh toán VNPAY...'), backgroundColor: Colors.blue),
      );
    }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    final mockOrderCode = 'CF-${1000 + DateTime.now().second * 13}';

    // Mock create and add order to history
    final newOrder = MockOrder(
      id: 'ord_new_${DateTime.now().millisecondsSinceEpoch}',
      orderCode: mockOrderCode,
      branchName: MockData.branches[0].name,
      items: List.from(cartState.items),
      totalAmount: cartState.subtotal,
      discountAmount: cartState.discount,
      finalAmount: cartState.total,
      paymentMethod: _paymentMethod,
      status: 'PENDING',
      createdAt: DateTime.now(),
      source: 'MOBILE_APP',
    );
    MockData.orderHistory.insert(0, newOrder);

    // Clear cart
    context.read<CartBloc>().add(ClearCart());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đặt đơn hàng thành công! Mã đơn: $mockOrderCode'),
        backgroundColor: AppColors.success,
      ),
    );

    // Navigate to Order Tracking with order code as ID
    context.go('/track/${newOrder.id}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty && !_isProcessing) {
          // If cart gets cleared during check, navigate back
          return const Scaffold(body: Center(child: Text('Giỏ hàng trống')));
        }

        return LoadingOverlay(
          isLoading: _isProcessing,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branch selection preview card
                  _buildSectionTitle('CHI NHÁNH PHỤC VỤ'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, color: AppColors.accent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MockData.branches[0].name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                MockData.branches[0].address,
                                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes to Barista
                  _buildSectionTitle('GHI CHÚ PHA CHẾ'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'VD: ít đá nhiều sữa, không topping để riêng...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment method selector
                  _buildSectionTitle('PHƯƠNG THỨC THANH TOÁN'),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    'CASH',
                    'Tiền mặt tại quầy',
                    Icons.payments_outlined,
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    'MOMO',
                    'Ví điện tử MoMo',
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    'VNPAY',
                    'Cổng thanh toán VNPAY',
                    Icons.qr_code_scanner,
                    Colors.blue,
                  ),
                  const SizedBox(height: 24),

                  // Order Summary Card
                  _buildSectionTitle('TÓM TẮT ĐƠN HÀNG'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        ...state.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.product.name} (x${item.quantity})',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Size ${item.size} • Đường ${item.sugarLevel}% • Đá ${item.iceLevel}%',
                                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(currencyFormat.format(item.totalPrice)),
                              ],
                            ),
                          );
                        }),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            Text(currencyFormat.format(state.subtotal), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        if (state.discount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Giảm giá', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              Text('-${currencyFormat.format(state.discount)}', style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              currencyFormat.format(state.total),
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Place order action
                  CoffeeButton(
                    label: 'XÁC NHẬN ĐẶT HÀNG & THANH TOÁN',
                    onTap: () => _submitOrder(state),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.accent,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon, Color color) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              activeColor: AppColors.accent,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _paymentMethod = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
