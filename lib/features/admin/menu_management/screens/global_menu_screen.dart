import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';

class GlobalMenuScreen extends StatefulWidget {
  const GlobalMenuScreen({super.key});

  @override
  State<GlobalMenuScreen> createState() => _GlobalMenuScreenState();
}

class _GlobalMenuScreenState extends State<GlobalMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<MockProduct> _products = MockData.products;
  final List<MockCategory> _categories = MockData.categories;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Search & Filter
  String _productSearchQuery = "";
  String _selectedCategoryFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MockProduct> _getFilteredProducts() {
    List<MockProduct> list = _products;
    if (_selectedCategoryFilter != 'ALL') {
      list = list.where((p) => p.categoryId == _selectedCategoryFilter).toList();
    }
    if (_productSearchQuery.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(_productSearchQuery.toLowerCase())).toList();
    }
    return list;
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Thêm Danh Mục Mới', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Tên danh mục (vd: Trà Sữa)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Icon cảm xúc (vd: 🥛)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('HỦY', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final icon = iconController.text.trim();
                if (name.isEmpty || icon.isEmpty) return;

                setState(() {
                  _categories.add(
                    MockCategory(
                      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      icon: icon,
                    ),
                  );
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm danh mục $name thành công!'), backgroundColor: AppColors.success),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
              child: const Text('THÊM MỚI'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductSheet() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String categoryId = _categories[0].id;
    
    // Size prices
    final sPriceController = TextEditingController();
    final lPriceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thêm Sản Phẩm Mới Toàn Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent)),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tên món nước'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Mô tả chi tiết công thức'),
                    ),
                    const SizedBox(height: 12),
                    
                    // Category dropdown
                    const Text('Danh mục phân loại:', style: TextStyle(fontSize: 11, color: Colors.white30)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: categoryId,
                          dropdownColor: AppColors.surface,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => categoryId = val);
                            }
                          },
                          items: _categories.map((cat) {
                            return DropdownMenuItem(value: cat.id, child: Text('${cat.icon} ${cat.name}'));
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pricing options
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Giá bán cơ bản (Size M)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // S and L size offset price overrides
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Khấu trừ Size S (vd: 5000)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Phụ thu Size L (vd: 10000)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    CoffeeButton(
                      label: 'HOÀN TẤT THÊM MÓN',
                      onTap: () {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text) ?? 0;
                        if (name.isEmpty || price <= 0) return;

                        setState(() {
                          _products.add(
                            MockProduct(
                              id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              description: descController.text.trim(),
                              categoryId: categoryId,
                              basePrice: price,
                              imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=300&auto=format&fit=crop',
                              isAvailable: true,
                              sizes: const ['S', 'M', 'L'],
                              toppings: const [],
                            ),
                          );
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm sản phẩm $name vào hệ thống!'), backgroundColor: AppColors.success),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình thực đơn hệ thống', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📦 SẢN PHẨM'),
            Tab(text: '📁 DANH MỤC TỔNG'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Products
          Column(
            children: [
              // Search & Filter Panel
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          setState(() => _productSearchQuery = val);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Tìm món ăn/thức uống...',
                          prefixIcon: Icon(Icons.search, size: 18),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedCategoryFilter,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategoryFilter = val);
                        }
                      },
                      items: [
                        const DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                        ..._categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Products List
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(child: Text('Trống', style: TextStyle(color: Colors.white.withOpacity(0.2))))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(currencyFormat.format(product.basePrice), style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Đang bán:', style: TextStyle(fontSize: 10, color: Colors.white30)),
                                  Switch(
                                    value: product.isAvailable,
                                    activeColor: AppColors.accent,
                                    onChanged: (val) {
                                      setState(() {
                                        final prodIndex = _products.indexWhere((p) => p.id == product.id);
                                        if (prodIndex >= 0) {
                                          _products[prodIndex] = MockProduct(
                                            id: product.id,
                                            name: product.name,
                                            description: product.description,
                                            categoryId: product.categoryId,
                                            basePrice: product.basePrice,
                                            imageUrl: product.imageUrl,
                                            isAvailable: val,
                                            sizes: product.sizes,
                                            toppings: product.toppings,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          
          // Tab Categories
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.white60),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () {
                            setState(() {
                              _categories.removeWhere((c) => c.id == cat.id);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddProductSheet();
          } else {
            _showAddCategoryDialog();
          }
        },
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }
}
