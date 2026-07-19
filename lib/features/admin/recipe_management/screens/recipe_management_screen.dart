import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/bloc/auth_bloc.dart';

class RecipeManagementScreen extends StatefulWidget {
  const RecipeManagementScreen({super.key});

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  List<MockProduct> _products = [];
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _recipes = [];
  MockProduct? _selectedProduct;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = AuthBloc.currentUser?.token;
    if (token == null) {
      // Mock Fallback
      setState(() {
        _products = MockData.products;
        _selectedProduct = _products.isNotEmpty ? _products.first : null;
        _isLoading = false;
      });
      return;
    }

    try {
      final prods = await ApiService.instance.getProducts();
      final ingr = await ApiService.instance.getIngredients(token);
      final rec = await ApiService.instance.getRecipes(token);

      if (mounted) {
        setState(() {
          _products = prods;
          _ingredients = ingr;
          _recipes = rec;
          _selectedProduct = prods.isNotEmpty ? prods.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu công thức: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getCurrentRecipeItems() {
    if (_selectedProduct == null) return [];
    final currentId = int.tryParse(_selectedProduct!.id) ?? 0;
    return _recipes.where((r) => r['menuItemId'] == currentId).toList();
  }

  Future<void> _showAddIngredientDialog() async {
    if (_selectedProduct == null) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có nguyên liệu nào để chọn!'), backgroundColor: AppColors.error),
      );
      return;
    }

    Map<String, dynamic> selectedIngr = _ingredients.first;
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Thêm Định Lượng Món: ${_selectedProduct!.name}',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn nguyên liệu:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedIngr,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedIngr = val);
                          }
                        },
                        items: _ingredients.map((ing) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: ing,
                            child: Text(ing['ingredientName'] ?? 'Nguyên liệu'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Định lượng bắt buộc (kg hoặc lít):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'VD: 0.05',
                      fillColor: AppColors.background,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('HỦY', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(quantityController.text) ?? 0.0;
                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền định lượng hợp lệ!'), backgroundColor: AppColors.error),
                      );
                      return;
                    }

                    final token = AuthBloc.currentUser?.token;
                    final menuItemId = int.tryParse(_selectedProduct!.id) ?? 1;
                    final ingredientId = selectedIngr['id'] as int;

                    setState(() => _isLoading = true);
                    Navigator.pop(context);

                    bool success = false;
                    if (token != null) {
                      success = await ApiService.instance.updateRecipe(menuItemId, ingredientId, qty, token);
                    }

                    if (success) {
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật định lượng thành công!'), backgroundColor: AppColors.success),
                        );
                      }
                    } else {
                      setState(() {
                        // Mock local update
                        final existingIndex = _recipes.indexWhere((r) => r['menuItemId'] == menuItemId && r['ingredientId'] == ingredientId);
                        if (existingIndex >= 0) {
                          _recipes[existingIndex]['quantityRequired'] = qty;
                        } else {
                          _recipes.add({
                            'menuItemId': menuItemId,
                            'ingredientId': ingredientId,
                            'ingredientName': selectedIngr['ingredientName'],
                            'quantityRequired': qty,
                          });
                        }
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('LƯU'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRecipe = _getCurrentRecipeItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu Hình Định Lượng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Row(
              children: [
                // Products list on the left
                Container(
                  width: 140,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final isSelected = _selectedProduct?.id == p.id;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedProduct = p;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          color: isSelected ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.accent : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Selected Product Recipe configuration on the right
                Expanded(
                  child: _selectedProduct == null
                      ? const Center(child: Text('Chọn một món ăn', style: TextStyle(color: Colors.white54)))
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Info Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _selectedProduct!.imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedProduct!.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Giá cơ bản: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_selectedProduct!.basePrice)}',
                                            style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Nguyên Liệu Cấu Thành',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: AppColors.accent, size: 24),
                                    onPressed: _showAddIngredientDialog,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Expanded(
                                child: currentRecipe.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Chưa có nguyên liệu cấu thành.\nVui lòng bấm (+) để thêm.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: currentRecipe.length,
                                        itemBuilder: (context, idx) {
                                          final item = currentRecipe[idx];
                                          final reqVal = item['quantityRequired'] != null
                                              ? double.tryParse(item['quantityRequired'].toString()) ?? 0.0
                                              : 0.0;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  item['ingredientName'] ?? 'Nguyên liệu',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  '${reqVal.toStringAsFixed(3)} kg/lít',
                                                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
class NumberFormat {
  static NumberFormat currency({required String locale, required String symbol}) => NumberFormat();
  String format(double val) {
    return '${val.toStringAsFixed(0)}đ';
  }
}
