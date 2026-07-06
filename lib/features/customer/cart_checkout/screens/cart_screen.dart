import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../bloc/cart_bloc.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim();
    if (code.isNotEmpty) {
      context.read<CartBloc>().add(ApplyDiscountCoupon(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state.isCouponValid && state.appliedCoupon != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Áp dụng mã ${state.appliedCoupon!.code} thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        final hasItems = state.items.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Giỏ hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (hasItems)
                TextButton(
                  onPressed: () {
                    context.read<CartBloc>().add(ClearCart());
                  },
                  child: const Text('Xóa tất cả', style: TextStyle(color: AppColors.error)),
                ),
            ],
          ),
          body: !hasItems
              ? _buildEmptyCart()
              : Column(
                  children: [
                    // Cart List Items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              context.read<CartBloc>().add(RemoveFromCart(item.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã xóa ${item.product.name} khỏi giỏ hàng!'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                children: [
                                  // Product image thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.product.imageUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Product selections display
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Size ${item.size} • Đường ${item.sugarLevel}% • Đá ${item.iceLevel == 0 ? 'Không' : item.iceLevel == 50 ? 'Ít' : 'Thường'}',
                                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                                        ),
                                        if (item.selectedToppings.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '+ Toppings: ${item.selectedToppings.map((t) => t.name).join(", ")}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.accent),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  
                                  // Quantity adjuster & pricing
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(item.totalPrice),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildQuantityButton(
                                            Icons.remove,
                                            () {
                                              context.read<CartBloc>().add(
                                                    UpdateCartItemQuantity(item.id, item.quantity - 1),
                                                  );
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              item.quantity.toString(),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          _buildQuantityButton(
                                            Icons.add,
                                            () {
                                              context.read<CartBloc>().add(
                                                    UpdateCartItemQuantity(item.id, item.quantity + 1),
                                                  );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Coupon Code Input Section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      color: AppColors.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập mã giảm giá (vd: COFFEE10, SAVE20K)',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                                    fillColor: AppColors.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _applyCoupon,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: AppColors.background,
                                    elevation: 0,
                                  ),
                                  child: const Text('ÁP DỤNG'),
                                ),
                              ),
                            ],
                          ),
                          // Display active promo code banner
                          if (state.isCouponValid && state.appliedCoupon != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đã áp dụng mã: ${state.appliedCoupon!.code} (${state.appliedCoupon!.description})',
                                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bill Summary Calculation Cards
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tạm tính', style: TextStyle(color: Colors.white54)),
                              Text(currencyFormat.format(state.subtotal), style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          if (state.discount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Giảm giá khuyến mãi', style: TextStyle(color: Colors.white54)),
                                Text('-${currencyFormat.format(state.discount)}', style: const TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TỔNG CỘNG',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                currencyFormat.format(state.total),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CoffeeButton(
                            label: 'TIẾN HÀNH ĐẶT HÀNG',
                            onTap: () => context.push('/checkout'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.accent.withOpacity(0.3)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Giỏ hàng của bạn đang trống!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy duyệt qua menu của chúng tôi và chọn những thức uống thơm ngon nhất nhé.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            CoffeeButton(
              label: 'XEM THỰC ĐƠN NGAY',
              width: 200,
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 14, color: AppColors.accent),
        onPressed: onPressed,
      ),
    );
  }
}
