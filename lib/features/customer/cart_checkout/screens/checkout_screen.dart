import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../bloc/cart_bloc.dart';

import '../../../../core/network/api_service.dart';
import 'payment_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'CASH'; // CASH, MOMO, VNPAY, PAYOS
  final _notesController = TextEditingController();
  final _pointsController = TextEditingController(text: '0');
  bool _isProcessing = false;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void dispose() {
    _notesController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _showMockPaymentGateway(String method, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: method == 'MOMO'
                    ? Image.network(
                        'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png',
                        height: 50,
                      )
                    : const Text(
                        'VNPay',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                'Đang kết nối cổng thanh toán $method...',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng không đóng ứng dụng hoặc chuyển hướng màn hình',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        onSuccess();
      }
    });
  }

  Future<void> _submitOrder(CartState cartState) async {
    final currentUser = AuthBloc.currentUser;
    final token = currentUser?.token;
    final branchId = int.tryParse(MockData.selectedBranch?.id ?? '1') ?? 1;
    final redeemedPoints = int.tryParse(_pointsController.text) ?? 0;

    void executePlaceOrder() {
      if (token != null) {
        context.read<CartBloc>().add(
          PlaceOrderEvent(
            branchId: branchId,
            fulfillmentMode: 'Takeaway',
            paymentMethod: _paymentMethod,
            token: token,
            redeemPoints: redeemedPoints,
          ),
        );
      } else {
        // Local fallback for offline/development mode
        setState(() {
          _isProcessing = true;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
          });
          final mockOrderCode = 'CF-${1000 + DateTime.now().second * 13}';
          final newOrder = MockOrder(
            id: 'ord_new_${DateTime.now().millisecondsSinceEpoch}',
            orderCode: mockOrderCode,
            branchName: (MockData.selectedBranch ?? MockData.branches[0]).name,
            items: List.from(cartState.items),
            totalAmount: cartState.subtotal,
            discountAmount: cartState.discount + (redeemedPoints * 100.0),
            finalAmount: (cartState.total - (redeemedPoints * 100.0)).clamp(0, double.infinity),
            paymentMethod: _paymentMethod,
            status: 'PENDING',
            createdAt: DateTime.now(),
            source: 'MOBILE_APP',
          );
          MockData.orderHistory.insert(0, newOrder);
          context.read<CartBloc>().add(ClearCart());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đặt đơn hàng thành công! Mã đơn: $mockOrderCode'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/track/${newOrder.id}');
        });
      }
    }

    if (_paymentMethod == 'MOMO' || _paymentMethod == 'VNPAY' || _paymentMethod == 'PAYOS') {
      if (token != null) {
        try {
          setState(() => _isProcessing = true);
          final orderCode = 'CF-${1000 + DateTime.now().second * 13}';
          final payosRes = await ApiService.instance.createPayOSLink(
            amount: cartState.total.toInt(),
            orderCode: orderCode,
            token: token,
          );
          setState(() => _isProcessing = false);

          final checkoutUrl = payosRes['checkoutUrl'] as String?;
          if (checkoutUrl != null && checkoutUrl.isNotEmpty && mounted) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentWebViewScreen(checkoutUrl: checkoutUrl),
              ),
            );
            if (result == 'success') {
              executePlaceOrder();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã hủy thanh toán trực tuyến!'), backgroundColor: AppColors.warning),
                );
              }
            }
            return;
          }
        } catch (e) {
          setState(() => _isProcessing = false);
          print('PayOS error, fallback to mock: $e');
        }
      }
      _showMockPaymentGateway(_paymentMethod, executePlaceOrder);
    } else {
      executePlaceOrder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state.isOrderSuccess && state.orderResponse != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đặt đơn hàng thành công! Mã đơn: ${state.orderResponse!.orderCode}'),
              backgroundColor: AppColors.success,
            ),
          );
          // Map to local mock order history just to show on screens
          final mockOrder = MockOrder(
            id: state.orderResponse!.orderId.toString(),
            orderCode: state.orderResponse!.orderCode,
            branchName: (MockData.selectedBranch ?? MockData.branches[0]).name,
            items: const [],
            totalAmount: state.orderResponse!.totalAmount,
            discountAmount: state.orderResponse!.discountAmount,
            finalAmount: state.orderResponse!.finalAmount,
            paymentMethod: _paymentMethod,
            status: state.orderResponse!.orderStatus,
            createdAt: DateTime.now(),
            source: 'MOBILE_APP',
          );
          MockData.orderHistory.insert(0, mockOrder);
          context.go('/track/${state.orderResponse!.orderId}');
        } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading || _isProcessing;

        if (state.items.isEmpty && !isLoading) {
          return const Scaffold(body: Center(child: Text('Giỏ hàng trống')));
        }

        return LoadingOverlay(
          isLoading: isLoading,
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
                                (MockData.selectedBranch ?? MockData.branches[0]).name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (MockData.selectedBranch ?? MockData.branches[0]).address,
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

                  // Loyalty Points Redemption
                  _buildSectionTitle('SỬ DỤNG ĐIỂM TÍCH LŨY'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số điểm hiện có: ${AuthBloc.currentUser?.loyaltyPoints ?? 0} điểm',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              'Đổi tối đa: ${currencyFormat.format((AuthBloc.currentUser?.loyaltyPoints ?? 0) * 100)}',
                              style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _pointsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Số điểm cần đổi (1 điểm = 100đ)...',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (val) {
                                  final pts = int.tryParse(val) ?? 0;
                                  final maxPts = AuthBloc.currentUser?.loyaltyPoints ?? 0;
                                  if (pts > maxPts) {
                                    _pointsController.text = maxPts.toString();
                                    _pointsController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: _pointsController.text.length),
                                    );
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '- ${currencyFormat.format((int.tryParse(_pointsController.text) ?? 0) * 100)}',
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
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
                        if ((int.tryParse(_pointsController.text) ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Đổi điểm tích lũy', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              Text('-${currencyFormat.format((int.tryParse(_pointsController.text) ?? 0) * 100.0)}', style: const TextStyle(color: AppColors.error, fontSize: 13)),
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
                              currencyFormat.format((state.total - ((int.tryParse(_pointsController.text) ?? 0) * 100.0)).clamp(0.0, double.infinity)),
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
