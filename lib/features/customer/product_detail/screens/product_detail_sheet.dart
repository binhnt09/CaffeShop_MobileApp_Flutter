import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../cart_checkout/bloc/cart_bloc.dart';

class ProductDetailSheet extends StatefulWidget {
  final MockProduct product;
  const ProductDetailSheet({super.key, required this.product});

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  Map<String, dynamic>? _selectedSizeOption;
  Map<String, dynamic>? _selectedSugarOption;
  Map<String, dynamic>? _selectedIceOption;
  List<MockTopping> _toppings = [];
  int _quantity = 1;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  List<Map<String, dynamic>> _sizes = [];
  List<Map<String, dynamic>> _sugarLevels = [];
  List<Map<String, dynamic>> _iceLevels = [];
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _loadCustomizations();
  }

  Future<void> _loadCustomizations() async {
    try {
      final data = await ApiService.instance.getCustomizationsForProduct(widget.product.id);
      if (mounted) {
        setState(() {
          _sizes = List<Map<String, dynamic>>.from(data['sizes'] ?? []);
          _sugarLevels = List<Map<String, dynamic>>.from(data['sugarLevels'] ?? []);
          _iceLevels = List<Map<String, dynamic>>.from(data['iceLevels'] ?? []);
          _toppings = List<MockTopping>.from(data['toppings'] ?? []);

          if (_sizes.isNotEmpty) {
            _selectedSizeOption = _sizes.firstWhere(
              (s) => s['name'].toString().toUpperCase().contains('M'),
              orElse: () => _sizes.first,
            );
          }
          if (_sugarLevels.isNotEmpty) {
            _selectedSugarOption = _sugarLevels.firstWhere(
              (s) => s['name'].toString().contains('100'),
              orElse: () => _sugarLevels.first,
            );
          }
          if (_iceLevels.isNotEmpty) {
            _selectedIceOption = _iceLevels.firstWhere(
              (s) => s['name'].toString().contains('100') || s['name'].toString().contains('Bình thường'),
              orElse: () => _iceLevels.first,
            );
          }
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sizes = [{'id': 2, 'name': 'Size M', 'extraPrice': 0.0}];
          _sugarLevels = [{'id': 4, 'name': '100% Đường', 'extraPrice': 0.0}];
          _iceLevels = [{'id': 8, 'name': '100% Đá', 'extraPrice': 0.0}];
          _toppings = [];
          _isLoadingOptions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải tùy chọn: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  double get _currentUnitPrice {
    double price = widget.product.basePrice;
    if (_selectedSizeOption != null) {
      price += _selectedSizeOption!['extraPrice'] as double;
    }
    if (_selectedSugarOption != null) {
      price += _selectedSugarOption!['extraPrice'] as double;
    }
    if (_selectedIceOption != null) {
      price += _selectedIceOption!['extraPrice'] as double;
    }
    for (var topping in _toppings) {
      if (topping.isSelected) {
        price += topping.price;
      }
    }
    return price;
  }

  double get _currentTotalPrice => _currentUnitPrice * _quantity;

  void _addToCart() {
    final selectedTops = _toppings.where((t) => t.isSelected).toList();
    
    final List<int> customizationOptionIds = [];
    if (_selectedSizeOption != null) customizationOptionIds.add(_selectedSizeOption!['id'] as int);
    if (_selectedSugarOption != null) customizationOptionIds.add(_selectedSugarOption!['id'] as int);
    if (_selectedIceOption != null) customizationOptionIds.add(_selectedIceOption!['id'] as int);
    customizationOptionIds.addAll(selectedTops.map((t) => int.parse(t.id)));

    String sizeLabel = _selectedSizeOption != null ? _selectedSizeOption!['name'].toString().replaceAll('Size ', '') : 'M';
    int sugarPercent = _selectedSugarOption != null
        ? (int.tryParse(_selectedSugarOption!['name'].toString().replaceAll('% Đường', '').replaceAll(' Đường', '')) ?? 100)
        : 100;
    int icePercent = _selectedIceOption != null
        ? (_selectedIceOption!['name'].toString().contains('Không') ? 0 : _selectedIceOption!['name'].toString().contains('Ít') ? 50 : 100)
        : 100;

    final cartItem = MockCartItem(
      id: const Uuid().v4(),
      product: widget.product,
      size: sizeLabel,
      sugarLevel: sugarPercent,
      iceLevel: icePercent,
      selectedToppings: selectedTops,
      quantity: _quantity,
      customizationOptionIds: customizationOptionIds,
    );

    context.read<CartBloc>().add(AddToCart(cartItem));
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${widget.product.name} ($sizeLabel) vào giỏ hàng!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: _isLoadingOptions
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        // Product Banner Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.product.imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Product General Info
                        Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.description,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        
                        const Divider(),
                        
                        // Size custom option
                        if (_sizes.isNotEmpty) ...[
                          _buildSectionHeader('Chọn Size (Bắt buộc)'),
                          const SizedBox(height: 8),
                          Row(
                            children: _sizes.map((sizeOpt) {
                              String label = sizeOpt['name'].toString().replaceAll('Size ', '');
                              double diff = sizeOpt['extraPrice'] as double;
                        
                              String diffText = diff == 0
                                  ? 'Cơ bản'
                                  : diff > 0
                                      ? '+${currencyFormat.format(diff)}'
                                      : '${currencyFormat.format(diff)}';
                                  
                              final isSelected = _selectedSizeOption?['id'] == sizeOpt['id'];
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSizeOption = sizeOpt;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.accent : Colors.white12,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Size $label',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          diffText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected ? AppColors.accent : Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Sugar Level custom option
                        if (_sugarLevels.isNotEmpty) ...[
                          _buildSectionHeader('Chọn mức Đường'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _sugarLevels.map((sugarOpt) {
                              final isSelected = _selectedSugarOption?['id'] == sugarOpt['id'];
                              return ChoiceChip(
                                label: Text(sugarOpt['name'].toString().replaceAll(' Đường', '')),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedSugarOption = sugarOpt;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Ice Level custom option
                        if (_iceLevels.isNotEmpty) ...[
                          _buildSectionHeader('Chọn mức Đá'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _iceLevels.map((iceOpt) {
                              final isSelected = _selectedIceOption?['id'] == iceOpt['id'];
                              return ChoiceChip(
                                label: Text(iceOpt['name'].toString().replaceAll(' Đá', '')),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedIceOption = iceOpt;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                  
                  // Toppings custom list option
                  if (_toppings.isNotEmpty) ...[
                    _buildSectionHeader('Chọn Toppings kèm theo (Tùy chọn)'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _toppings.map((topping) {
                          return CheckboxListTile(
                            value: topping.isSelected,
                            activeColor: AppColors.accent,
                            checkColor: AppColors.background,
                            title: Text(topping.name, style: const TextStyle(fontSize: 14, color: Colors.white)),
                            subtitle: Text('+${currencyFormat.format(topping.price)}', style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                            onChanged: (val) {
                              setState(() {
                                topping.isSelected = val ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]
                ],
              ),
            ),
            
            // Bottom Action Drawer (Quantity & Add to Cart button)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  // Quantity adjust selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số lượng sản phẩm',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(
                        children: [
                          _buildQuantityButton(
                            Icons.remove,
                            () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _quantity.toString(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          _buildQuantityButton(
                            Icons.add,
                            () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Total price display & Add button
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TỔNG TIỀN TẠM TÍNH', style: TextStyle(fontSize: 10, color: Colors.white38)),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(_currentTotalPrice),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CoffeeButton(
                          label: 'THÊM VÀO GIỎ HÀNG',
                          onTap: _addToCart,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.accent,
      ),
    );
  }



  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.white10),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.accent),
        onPressed: onPressed,
      ),
    );
  }
}
