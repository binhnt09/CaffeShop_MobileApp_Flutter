import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/network/api_service.dart';
import '../product_detail/screens/product_detail_sheet.dart';
import '../cart_checkout/bloc/cart_bloc.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  List<MockCategory> _categories = [];
  List<MockProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cats = await ApiService.instance.getCategories();
      
      String? branchId = MockData.selectedBranch?.id;
      if (branchId == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          branchId = prefs.getString('selected_branch_id');
          if (branchId != null) {
            // Restore selection in MockData if it was persisted
            final branches = await ApiService.instance.getBranches();
            final matched = branches.where((b) => b.id == branchId);
            if (matched.isNotEmpty) {
              MockData.selectedBranch = matched.first;
            }
          }
        } catch (_) {}
      }

      final List<MockProduct> prods = branchId != null
          ? await ApiService.instance.getProductsByBranch(branchId)
          : await ApiService.instance.getProducts();

      if (mounted) {
        setState(() {
          _categories = cats;
          _products = prods;
          _tabController = TabController(length: _categories.length + 1, vsync: this);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [];
          _products = [];
          _tabController = TabController(length: 1, vsync: this);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thực đơn: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MockProduct> _getFilteredProducts(String? categoryId) {
    List<MockProduct> list = _products;
    
    // Filter by Category
    if (categoryId != null) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    
    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    return list;
  }

  void _showProductDetail(MockProduct product) {
    if (!product.isAvailable) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProductDetailSheet(product: product);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ĐẶT MÓN TẠI',
              style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  MockData.branches[0].name.replaceAll('CaffeShop ', ''),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Cart Icon with Badge
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              final totalQuantity = state.items.fold<int>(0, (sum, item) => sum + item.quantity);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    onPressed: () => context.push('/cart'),
                  ),
                  if (totalQuantity > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          totalQuantity.toString(),
                          style: const TextStyle(
                            color: AppColors.background,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _products.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_cafe_outlined, size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'Không Có Sản Phẩm Nào',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Thực đơn chi nhánh này trống hoặc chưa cấu hình trên máy chủ. Bạn có muốn tải thực đơn mẫu không?',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            setState(() {
                              _categories = MockData.categories;
                              _products = MockData.products;
                              _tabController = TabController(length: _categories.length + 1, vsync: this);
                            });
                          },
                          child: const Text('SỬ DỤNG THỰC ĐƠN THỬ NGHIỆM', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm trà, cà phê, bánh ngọt...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white24),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white24),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Horizontal Category Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: [
                    const Tab(text: 'Tất cả'),
                    ..._categories.map((cat) {
                      IconData iconData = Icons.local_cafe;
                      if (cat.icon == 'emoji_food_beverage') iconData = Icons.emoji_food_beverage;
                      if (cat.icon == 'cake') iconData = Icons.cake;
                      if (cat.icon == 'ac_unit') iconData = Icons.ac_unit;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconData, size: 16),
                            const SizedBox(width: 6),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 8),

                // Menu Grid Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductGrid(null), // All products
                      ..._categories.map((cat) => _buildProductGrid(cat.id)),
                    ],
                  ),
                ),
              ],
            ),
      // Cart Floating Action Button
      floatingActionButton: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) return const SizedBox.shrink();
          final totalQuantity = state.items.fold<int>(0, (sum, item) => sum + item.quantity);
          return FloatingActionButton.extended(
            onPressed: () => context.push('/cart'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag, color: AppColors.accent),
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      totalQuantity.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
            label: Row(
              children: [
                const Text('Xem giỏ hàng • '),
                Text(
                  currencyFormat.format(state.total),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProductGrid(String? categoryId) {
    final filteredProducts = _getFilteredProducts(categoryId);

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 8),
            Text(
              'Không tìm thấy sản phẩm nào!',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return GestureDetector(
          onTap: () => _showProductDetail(product),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Expanded(
                      flex: 6,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            product.isAvailable ? Colors.transparent : Colors.black.withOpacity(0.4),
                            BlendMode.dstATop,
                          ),
                          child: Image.network(
                            product.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, err, stack) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.coffee, color: Colors.white12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Product Info
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.description,
                                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currencyFormat.format(product.basePrice),
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (product.isAvailable)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Out of stock overlay badge
                if (!product.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: const Text(
                            'HẾT HÀNG',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0, // Menu Tab is selected
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.white.withOpacity(0.5),
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        if (index == 1) {
          context.push('/loyalty');
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
