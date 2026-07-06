import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../bloc/pos_bloc.dart';

class POSCounterScreen extends StatefulWidget {
  const POSCounterScreen({super.key});

  @override
  State<POSCounterScreen> createState() => _POSCounterScreenState();
}

class _POSCounterScreenState extends State<POSCounterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashReceivedController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _activeCategory = 'cat_coffee';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: MockData.categories.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _activeCategory = MockData.categories[_tabController.index].id;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashReceivedController.dispose();
    super.dispose();
  }

  List<MockProduct> _getCategoryProducts() {
    return MockData.products.where((p) => p.categoryId == _activeCategory).toList();
  }

  void _showCheckoutDialog(BuildContext context, POSState posState) {
    if (posState.orderItems.isEmpty) return;

    _cashReceivedController.clear();
    String method = 'CASH';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Thanh Toán Tại Quầy', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng tiền đơn hàng: ${currencyFormat.format(posState.totalAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 20),
                    
                    // Payment selection
                    const Text('Hình thức thanh toán:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.payments, size: 16), SizedBox(width: 4), Text('Tiền mặt')],
                            ),
                            selected: method == 'CASH',
                            onSelected: (selected) {
                              if (selected) setModalState(() => method = 'CASH');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.qr_code, size: 16), SizedBox(width: 4), Text('Mã QR')],
                            ),
                            selected: method == 'QR',
                            onSelected: (selected) {
                              if (selected) setModalState(() => method = 'QR');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Detail options for Cash vs QR
                    if (method == 'CASH') ...[
                      const Text('Số tiền khách đưa:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cashReceivedController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tiền nhận (vd: 100000)',
                          fillColor: AppColors.background,
                        ),
                        onChanged: (val) {
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_cashReceivedController.text.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final received = double.tryParse(_cashReceivedController.text) ?? 0;
                            final change = received - posState.totalAmount;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tiền thừa thối khách:'),
                                Text(
                                  change >= 0 ? currencyFormat.format(change) : 'Chưa đủ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: change >= 0 ? AppColors.success : AppColors.error,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ] else ...[
                      // Display dynamic QR Code mockup
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.qr_code_2, size: 140, color: Colors.grey.shade900),
                            ),
                            const SizedBox(height: 8),
                            const Text('Khách hàng quét mã QR để thanh toán', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('HỦY', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final received = method == 'CASH'
                        ? (double.tryParse(_cashReceivedController.text) ?? 0)
                        : posState.totalAmount;

                    if (method == 'CASH' && received < posState.totalAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tiền nhận từ khách không đủ!'), backgroundColor: AppColors.error),
                      );
                      return;
                    }

                    // Complete POS order
                    context.read<POSBloc>().add(
                          POSCheckoutRequested(
                            paymentMethod: method,
                            amountReceived: received,
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
                  child: const Text('HOÀN THÀNH', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _printReceipt(String orderCode, double total) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.print, color: Colors.white),
            const SizedBox(width: 8),
            Text('Đang kết nối máy in Bill Bluetooth và in hóa đơn $orderCode...'),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<POSBloc, POSState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.error),
          );
        } else if (state.isSuccess && state.lastOrderCode != null) {
          // Success Checkout
          _printReceipt(state.lastOrderCode!, state.totalAmount);
          
          if (state.changeReturned > 0) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Thối Tiền Thừa'),
                content: Text(
                  'Thối lại cho khách:\n${currencyFormat.format(state.changeReturned)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  )
                ],
              ),
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('POS Bán Hàng Tại Quầy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                tooltip: 'Lịch sử hóa đơn',
                onPressed: () => context.push('/pos/history'),
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: AppColors.error),
                tooltip: 'Đăng xuất',
                onPressed: () {
                  context.read<POSBloc>().add(POSClearOrder());
                  context.go('/login');
                },
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              if (isWide) {
                // Side-by-Side Split Tablet layout
                return Row(
                  children: [
                    // Left Menu panel (60%)
                    Expanded(
                      flex: 6,
                      child: _buildMenuPanel(),
                    ),
                    // Right Bill panel (40%)
                    Expanded(
                      flex: 4,
                      child: _buildOrderSummaryPanel(state),
                    ),
                  ],
                );
              } else {
                // Vertical Split mobile layout
                return Column(
                  children: [
                    Expanded(child: _buildMenuPanel()),
                    Container(
                      height: 220,
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white12)),
                      ),
                      child: _buildOrderSummaryPanel(state),
                    ),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuPanel() {
    final products = _getCategoryProducts();
    return Column(
      children: [
        // Categories list selectors
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: MockData.categories.map((cat) => Tab(text: '${cat.icon} ${cat.name}')).toList(),
        ),
        const SizedBox(height: 8),
        
        // Products list grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  if (product.isAvailable) {
                    context.read<POSBloc>().add(POSAddItem(product));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              product.isAvailable ? Colors.transparent : Colors.black.withOpacity(0.5),
                              BlendMode.dstATop,
                            ),
                            child: Image.network(
                              product.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // Text info
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormat.format(product.basePrice),
                              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryPanel(POSState state) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HÓA ĐƠN TẠM', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 12)),
              Text('Món chọn: ${state.orderItems.length}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
          const Divider(),
          
          // Order list items
          Expanded(
            child: state.orderItems.isEmpty
                ? const Center(child: Text('Hãy chọn các món nước ở thực đơn bên trái', style: TextStyle(fontSize: 12, color: Colors.white24)))
                : ListView.builder(
                    itemCount: state.orderItems.length,
                    itemBuilder: (context, index) {
                      final item = state.orderItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('Size ${item.size}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                ],
                              ),
                            ),
                            
                            // Adjust quantity
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.accent),
                                  onPressed: () {
                                    context.read<POSBloc>().add(POSUpdateQuantity(item.id, item.quantity - 1));
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.accent),
                                  onPressed: () {
                                    context.read<POSBloc>().add(POSUpdateQuantity(item.id, item.quantity + 1));
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(currencyFormat.format(item.totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          
          // Total amount calculation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TỔNG TIỀN PHẢI THU:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                currencyFormat.format(state.totalAmount),
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<POSBloc>().add(POSClearOrder()),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('XÓA ĐƠN', style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.orderItems.isEmpty ? null : () => _showCheckoutDialog(context, state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('THANH TOÁN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
