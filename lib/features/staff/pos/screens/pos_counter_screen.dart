import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/network/api_service.dart';
import '../bloc/pos_bloc.dart';
import '../../../auth/bloc/auth_bloc.dart';

class POSCounterScreen extends StatefulWidget {
  const POSCounterScreen({super.key});

  @override
  State<POSCounterScreen> createState() => _POSCounterScreenState();
}

class _POSCounterScreenState extends State<POSCounterScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _cashReceivedController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  List<MockCategory> _categories = [];
  List<MockProduct> _allProducts = [];
  bool _isLoadingMenu = true;
  String _activeCategoryId = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    setState(() => _isLoadingMenu = true);
    try {
      final staffBranchId = AuthBloc.currentUser?.branchId ?? '1';
      final categories = await ApiService.instance.getCategories();
      final products = await ApiService.instance.getProductsByBranch(staffBranchId);

      if (mounted) {
        setState(() {
          _categories = categories.isNotEmpty
              ? categories
              : [
                  MockCategory(id: '1', name: 'Cà phê', icon: 'local_cafe'),
                  MockCategory(id: '2', name: 'Trà trái cây', icon: 'emoji_food_beverage'),
                ];
          _allProducts = products;
          _activeCategoryId = _categories.isNotEmpty ? _categories.first.id : '1';
          _tabController = TabController(length: _categories.length, vsync: this);
          _tabController!.addListener(() {
            if (_tabController != null && !_tabController!.indexIsChanging) {
              setState(() {
                _activeCategoryId = _categories[_tabController!.index].id;
              });
            }
          });
          _isLoadingMenu = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [
            MockCategory(id: '1', name: 'Cà phê', icon: 'local_cafe'),
            MockCategory(id: '2', name: 'Trà sữa', icon: 'emoji_food_beverage'),
          ];
          _allProducts = [];
          _activeCategoryId = '1';
          _tabController = TabController(length: _categories.length, vsync: this);
          _isLoadingMenu = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _cashReceivedController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MockProduct> _getFilteredProducts() {
    return _allProducts.where((p) {
      final matchesCategory = _searchQuery.isNotEmpty || p.categoryId == _activeCategoryId;
      final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.payment, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Thanh Toán Tại Quầy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cần thanh toán:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            currencyFormat.format(posState.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    if (method == 'CASH') ...[
                      const Text('Số tiền khách đưa:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cashReceivedController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Nhập tiền nhận (ví dụ: 100000)',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 12),
                      if (_cashReceivedController.text.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final received = double.tryParse(_cashReceivedController.text) ?? 0;
                            final change = received - posState.totalAmount;
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: change >= 0 ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tiền thối lại khách:', style: TextStyle(fontSize: 13)),
                                  Text(
                                    change >= 0 ? currencyFormat.format(change) : 'Chưa đủ tiền',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: change >= 0 ? AppColors.success : AppColors.error,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.qr_code_2, size: 130, color: Colors.grey.shade900),
                            ),
                            const SizedBox(height: 8),
                            const Text('Quét mã QR PayOS để thanh toán tự động', style: TextStyle(fontSize: 11, color: Colors.white54)),
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

                    final token = AuthBloc.currentUser?.token;
                    final branchId = int.tryParse(AuthBloc.currentUser?.branchId ?? '1') ?? 1;

                    context.read<POSBloc>().add(
                          POSCheckoutRequested(
                            paymentMethod: method,
                            amountReceived: received,
                            token: token,
                            branchId: branchId,
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showThermalReceiptPreviewModal(BuildContext context, POSState state) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final orderCode = 'POS-${now.millisecondsSinceEpoch.toString().substring(7)}';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Receipt Header
                  const Text('CAFFE SHOP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')),
                  const Text('HÓA ĐƠN TẠM TÍNH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54, fontFamily: 'monospace')),
                  const SizedBox(height: 6),
                  const Text('ĐC: 123 Nguyễn Văn Cừ, Q.5, TP.HCM', style: TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace'), textAlign: TextAlign.center),
                  const Text('Hotline: 1900 6868', style: TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace')),
                  const Divider(color: Colors.black38, thickness: 1, height: 16),

                  // Order Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mã đơn: $orderCode', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace')),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thu ngân: ${AuthBloc.currentUser?.fullName ?? "Staff"}', style: const TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace')),
                      const Text('Khu vực: Quầy 01', style: TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace')),
                    ],
                  ),
                  const Divider(color: Colors.black38, thickness: 1, height: 16),

                  // Items Table
                  Row(
                    children: const [
                      Expanded(flex: 4, child: Text('TÊN MÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'))),
                      Expanded(flex: 1, child: Text('SL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'), textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text('Đ.GIÁ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'), textAlign: TextAlign.right)),
                      Expanded(flex: 3, child: Text('T.TIỀN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'), textAlign: TextAlign.right)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...state.orderItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(flex: 4, child: Text('${item.product.name} (${item.size})', style: const TextStyle(fontSize: 11, color: Colors.black, fontFamily: 'monospace'))),
                              Expanded(flex: 1, child: Text('${item.quantity}', style: const TextStyle(fontSize: 11, color: Colors.black, fontFamily: 'monospace'), textAlign: TextAlign.center)),
                              Expanded(flex: 3, child: Text(currencyFormat.format(item.unitPrice), style: const TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace'), textAlign: TextAlign.right)),
                              Expanded(flex: 3, child: Text(currencyFormat.format(item.totalPrice), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace'), textAlign: TextAlign.right)),
                            ],
                          ),
                          if (item.selectedToppings.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                '+ Topping: ${item.selectedToppings.map((t) => t.name).join(', ')}',
                                style: const TextStyle(fontSize: 9, color: Colors.black54, fontStyle: FontStyle.italic, fontFamily: 'monospace'),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(color: Colors.black38, thickness: 1, height: 16),

                  // Total calculation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG TIỀN MÓN:', style: TextStyle(fontSize: 11, color: Colors.black, fontFamily: 'monospace')),
                      Text(currencyFormat.format(state.totalAmount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('VAT (8% đã gồm):', style: TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace')),
                      Text('Đã tính', style: TextStyle(fontSize: 10, color: Colors.black54, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('THANH TOÁN:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')),
                        Text(currencyFormat.format(state.totalAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('*** CẢM ƠN HẠN GẶP LẠI QUÝ KHÁCH ***', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54, fontFamily: 'monospace')),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCheckoutDialog(context, state);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('IN HÓA ĐƠN & THANH TOÁN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tạo hóa đơn thành công! Mã đơn: ${state.lastOrderCode}'),
              backgroundColor: AppColors.success,
            ),
          );
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
            title: Text(
              'POS Bán Hàng (Chi nhánh #${AuthBloc.currentUser?.branchId ?? "1"})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
            ),
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
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Tải lại menu',
                onPressed: _loadMenuData,
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
              final isWide = constraints.maxWidth > 750;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 6, child: _buildMenuPanel()),
                    Expanded(flex: 4, child: _buildOrderSummaryPanel(state)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Expanded(child: _buildMenuPanel()),
                    _buildMobileBottomCartBar(state),
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
    if (_isLoadingMenu) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final products = _getFilteredProducts();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm món theo tên...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
              fillColor: AppColors.surface,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        if (_tabController != null && _categories.isNotEmpty)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: Colors.white54,
            tabs: _categories.map((cat) => Tab(text: '${cat.name}')).toList(),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('Không tìm thấy sản phẩm nào', style: TextStyle(color: Colors.white38)))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
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
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  product.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800, child: const Icon(Icons.local_cafe, color: Colors.white38)),
                                ),
                              ),
                            ),
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
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: AppColors.accent, size: 18),
                  SizedBox(width: 6),
                  Text('HÓA ĐƠN TẠM TÍNH', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: state.orderItems.isEmpty ? null : () => _showThermalReceiptPreviewModal(context, state),
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Xem Trước Bill', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  side: const BorderSide(color: AppColors.accent),
                  foregroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: state.orderItems.isEmpty
                ? const Center(child: Text('Hãy chọn các món nước ở thực đơn bên trái', style: TextStyle(fontSize: 12, color: Colors.white24)))
                : ListView.builder(
                    itemCount: state.orderItems.length,
                    itemBuilder: (context, index) {
                      final item = state.orderItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('Size ${item.size}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.accent),
                                  onPressed: () {
                                    context.read<POSBloc>().add(POSUpdateQuantity(item.id, item.quantity - 1));
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.accent),
                                  onPressed: () {
                                    context.read<POSBloc>().add(POSUpdateQuantity(item.id, item.quantity + 1));
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(currencyFormat.format(item.totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TỔNG THANH TOÁN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              Text(
                currencyFormat.format(state.totalAmount),
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<POSBloc>().add(POSClearOrder()),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('THANH TOÁN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomCartBar(POSState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Đã chọn ${state.orderItems.length} món', style: const TextStyle(fontSize: 11, color: Colors.white54)),
              Text(
                currencyFormat.format(state.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 16),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: state.orderItems.isEmpty
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      builder: (context) => SizedBox(
                        height: 450,
                        child: _buildOrderSummaryPanel(state),
                      ),
                    );
                  },
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('HÓA ĐƠN TẠM & THANH TOÁN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
