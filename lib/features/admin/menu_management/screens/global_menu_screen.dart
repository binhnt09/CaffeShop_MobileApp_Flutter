import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/bloc/auth_bloc.dart';

class GlobalMenuScreen extends StatefulWidget {
  const GlobalMenuScreen({super.key});

  @override
  State<GlobalMenuScreen> createState() => _GlobalMenuScreenState();
}

class _GlobalMenuScreenState extends State<GlobalMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MockProduct> _products = [];
  List<MockCategory> _categories = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Search & Filter
  String _productSearchQuery = "";
  String _selectedCategoryFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cats = await ApiService.instance.getCategories();
      final prods = await ApiService.instance.getProducts();
      if (mounted) {
        setState(() {
          _categories = cats;
          _products = prods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [];
          _products = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu thực đơn: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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

  void _showCategoryDialog({MockCategory? categoryToEdit}) {
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    final iconController = TextEditingController(text: categoryToEdit?.icon ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(categoryToEdit == null ? 'Thêm Danh Mục Mới' : 'Sửa Danh Mục', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
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
              onPressed: () async {
                final name = nameController.text.trim();
                final icon = iconController.text.trim();
                if (name.isEmpty || icon.isEmpty) return;

                final token = AuthBloc.currentUser?.token;
                if (token != null) {
                  setState(() => _isLoading = true);
                  final cat = MockCategory(
                    id: categoryToEdit?.id ?? '0',
                    name: name,
                    icon: icon,
                  );
                  bool success = false;
                  if (categoryToEdit == null) {
                    success = await ApiService.instance.createCategory(cat, token);
                  } else {
                    success = await ApiService.instance.updateCategory(cat, token);
                  }
                  if (success) {
                    await _loadData();
                  } else {
                    setState(() => _isLoading = false);
                  }
                } else {
                  setState(() {
                    if (categoryToEdit == null) {
                      _categories.add(
                        MockCategory(
                          id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          icon: icon,
                        ),
                      );
                    } else {
                      final index = _categories.indexWhere((c) => c.id == categoryToEdit.id);
                      if (index >= 0) {
                        _categories[index] = MockCategory(
                          id: categoryToEdit.id,
                          name: name,
                          icon: icon,
                        );
                      }
                    }
                  });
                }
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cập nhật danh mục $name thành công!'), backgroundColor: AppColors.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
              child: Text(categoryToEdit == null ? 'THÊM MỚI' : 'CẬP NHẬT'),
            ),
          ],
        );
      },
    );
  }

  void _showProductFormSheet({MockProduct? productToEdit}) {
    final nameController = TextEditingController(text: productToEdit?.name ?? '');
    final descController = TextEditingController(text: productToEdit?.description ?? '');
    final priceController = TextEditingController(text: productToEdit != null ? productToEdit.basePrice.toStringAsFixed(0) : '');
    final imageUrlController = TextEditingController(text: productToEdit?.imageUrl ?? '');
    String categoryId = productToEdit?.categoryId ?? (_categories.isNotEmpty ? _categories[0].id : '1');
    
    // Size prices
    final sPriceController = TextEditingController(text: '5000');
    final lPriceController = TextEditingController(text: '10000');

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
                    Text(productToEdit == null ? 'Thêm Sản Phẩm Mới Toàn Hệ Thống' : 'Sửa Sản Phẩm Hệ Thống', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent)),
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
                    TextField(
                      controller: imageUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Đường dẫn ảnh sản phẩm (URL)',
                        hintText: 'https://images.unsplash.com/...',
                      ),
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
                            decoration: const InputDecoration(
                              labelText: 'Phụ thu Size L (vd: 10000)',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),CoffeeButton(
                      label: productToEdit == null ? 'HOÀN TẤT THÊM MÓN' : 'CẬP NHẬT MÓN',
                      onTap: () async {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text) ?? 0;
                        if (name.isEmpty || price <= 0) return;

                        final inputUrl = imageUrlController.text.trim();
                        final finalImageUrl = inputUrl.isNotEmpty ? inputUrl : 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=300';

                        final token = AuthBloc.currentUser?.token;
                        setState(() => _isLoading = true);
                        if (productToEdit == null) {
                          final newProd = MockProduct(
                            id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            description: descController.text.trim(),
                            categoryId: categoryId,
                            basePrice: price,
                            imageUrl: finalImageUrl,
                            isAvailable: true,
                            sizes: const ['S', 'M', 'L'],
                            toppings: const [],
                          );
                          if (token != null) {
                            await ApiService.instance.createMenuItem(newProd, token);
                            await _loadData();
                          } else {
                            setState(() {
                              _products.add(newProd);
                              _isLoading = false;
                            });
                          }
                        } else {
                          final updatedProd = MockProduct(
                            id: productToEdit.id,
                            name: name,
                            description: descController.text.trim(),
                            categoryId: categoryId,
                            basePrice: price,
                            imageUrl: finalImageUrl,
                            isAvailable: productToEdit.isAvailable,
                            sizes: productToEdit.sizes,
                            toppings: productToEdit.toppings,
                          );
                          if (token != null) {
                            await ApiService.instance.updateMenuItem(updatedProd, token);
                            await _loadData();
                          } else {
                            setState(() {
                              final idx = _products.indexWhere((p) => p.id == productToEdit.id);
                              if (idx >= 0) {
                                _products[idx] = updatedProd;
                              }
                              _isLoading = false;
                            });
                          }
                        }
                        
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã cập nhật sản phẩm $name thành công!'), backgroundColor: AppColors.success),
                          );
                        }
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
        title: const Text('Cấu hình thực đơn hệ thống', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
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
                                  errorBuilder: (context, error, stackTrace) => 
                                    Container(color: Colors.grey.shade900, width: 45, height: 45, child: const Icon(Icons.image_not_supported, size: 20)),
                                ),
                              ),
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(currencyFormat.format(product.basePrice), style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white60, size: 18),
                                    onPressed: () => _showProductFormSheet(productToEdit: product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _products.removeWhere((p) => p.id == product.id);
                                      });
                                    },
                                  ),
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
                          onPressed: () => _showCategoryDialog(categoryToEdit: cat),
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
            _showProductFormSheet();
          } else {
            _showCategoryDialog();
          }
        },
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }
}
