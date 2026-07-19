import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../../core/network/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<MockInventoryItem> _inventory = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _filterStatus = 'ALL'; // ALL, LOW, OK

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final token = AuthBloc.currentUser?.token;
    final branchId = AuthBloc.currentUser?.branchId ?? '1';

    if (token == null) {
      setState(() {
        _inventory = MockData.inventoryItems;
        _isLoading = false;
      });
      return;
    }

    try {
      final list = await ApiService.instance.getBranchInventory(branchId, token);
      if (mounted) {
        setState(() {
          _inventory = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inventory = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu kho: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<MockInventoryItem> _getFilteredInventory() {
    List<MockInventoryItem> list = _inventory;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Status filter
    if (_filterStatus == 'LOW') {
      list = list.where((item) => item.currentStock <= item.lowStockThreshold).toList();
    } else if (_filterStatus == 'OK') {
      list = list.where((item) => item.currentStock > item.lowStockThreshold).toList();
    }

    return list;
  }

  void _showAddStockSheet() {
    if (_inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kho hiện tại chưa có nguyên liệu nào!'), backgroundColor: AppColors.error),
      );
      return;
    }
    MockInventoryItem? selectedItem = _inventory.first;
    final quantityController = TextEditingController();

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lập Phiếu Nhập Kho Nội Bộ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown to pick ingredient
                  const Text('Chọn nguyên liệu:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MockInventoryItem>(
                        value: selectedItem,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (item) {
                          if (item != null) {
                            setModalState(() => selectedItem = item);
                          }
                        },
                        items: _inventory.map((item) {
                          return DropdownMenuItem<MockInventoryItem>(
                            value: item,
                            child: Text('${item.name} (Tồn: ${item.currentStock} ${item.unit})'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount input
                  const Text('Số lượng nhập:', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'VD: 10 (${selectedItem?.unit})',
                      fillColor: AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action
                  CoffeeButton(
                    label: 'HOÀN THÀNH NHẬP KHO',
                    onTap: () async {
                      final amount = double.tryParse(quantityController.text) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Số lượng nhập phải lớn hơn 0!'), backgroundColor: AppColors.error),
                        );
                        return;
                      }

                      if (selectedItem != null) {
                        final token = AuthBloc.currentUser?.token;
                        final branchId = int.tryParse(AuthBloc.currentUser?.branchId ?? '1') ?? 1;
                        final ingredientId = int.tryParse(selectedItem!.id) ?? 1;
                        final newTotal = selectedItem!.currentStock + amount;

                        if (token != null) {
                          setState(() => _isLoading = true);
                          final success = await ApiService.instance.updateBranchInventory(branchId, ingredientId, newTotal, token);
                          if (success) {
                            await _loadInventory();
                          } else {
                            setState(() => _isLoading = false);
                          }
                        } else {
                          setState(() {
                            selectedItem!.currentStock = newTotal;
                          });
                        }
                      }

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Nhập kho thành công! Đã thêm $amount ${selectedItem?.unit} vào ${selectedItem?.name}.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredInventory();
    final lowStockCount = _inventory.where((item) => item.currentStock <= item.lowStockThreshold).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Kho chi nhánh', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/manager/dashboard'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
          // Urgency Low Stock Warning banner
          if (lowStockCount > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cảnh báo: Có $lowStockCount nguyên liệu thô dưới mức tối thiểu. Cần nhập kho ngay!',
                      style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Cards overview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildOverviewCard('Tổng hàng', '${_inventory.length}', Colors.blue),
                const SizedBox(width: 10),
                _buildOverviewCard('Báo động đỏ', '$lowStockCount', AppColors.error),
                const SizedBox(width: 10),
                _buildOverviewCard('Đủ hàng', '${_inventory.length - lowStockCount}', AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filters and Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm nguyên liệu...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _filterStatus,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _filterStatus = val;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'LOW', child: Text('Cần nhập')),
                    DropdownMenuItem(value: 'OK', child: Text('Đầy đủ')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Active Inventory raw list
          Expanded(
            child: filteredList.isEmpty
                ? Center(child: Text('Không tìm thấy nguyên liệu nào.', style: TextStyle(color: Colors.white.withOpacity(0.2))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isLow = item.currentStock <= item.lowStockThreshold;
                      
                      Color progressColor = AppColors.success;
                      if (item.percentage < 0.25) {
                        progressColor = AppColors.error;
                      } else if (item.percentage < 0.5) {
                        progressColor = AppColors.warning;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLow ? AppColors.error.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  '${item.currentStock} / ${(item.lowStockThreshold * 3).toInt()} ${item.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLow ? AppColors.error : AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.percentage,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockSheet,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.white30)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
