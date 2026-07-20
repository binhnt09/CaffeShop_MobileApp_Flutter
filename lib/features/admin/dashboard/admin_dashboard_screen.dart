import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? baseUrl;

  const AdminDashboardScreen({
    super.key,
    this.baseUrl,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _apiUrl;

  // Global State Data
  List<dynamic> _branches = [];
  List<dynamic> _recipes = [];
  List<dynamic> _inventories = [];
  Map<String, dynamic>? _branchReport;
  Map<String, dynamic>? _consolidatedReport;

  bool _isLoadingBranches = false;
  bool _isLoadingRecipes = false;
  bool _isLoadingInventories = false;
  bool _isLoadingBranchReport = false;
  bool _isLoadingConsolidated = false;

  // Selected filters
  int _selectedBranchIdForReport = 1;
  String _selectedReportPeriod = 'TODAY';

  @override
  void initState() {
    super.initState();
    if (widget.baseUrl != null && widget.baseUrl!.isNotEmpty) {
      _apiUrl = widget.baseUrl!;
    } else if (!kIsWeb && Platform.isAndroid) {
      _apiUrl = 'http://10.0.2.2:8080/api';
    } else {
      _apiUrl = 'http://localhost:8080/api';
    }
    _tabController = TabController(length: 5, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    _fetchBranches();
    _fetchRecipes();
    _fetchInventories();
    _fetchBranchReport(_selectedBranchIdForReport, _selectedReportPeriod);
    _fetchConsolidatedReport();
  }

  // ==================== 1. API: BRANCH NETWORK (6.1) ====================
  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final response = await http.get(Uri.parse('$_apiUrl/branches'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          setState(() => _branches = body['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách chi nhánh: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _saveBranch(Map<String, dynamic> branchData, {int? id}) async {
    try {
      final isEdit = id != null;
      final url = isEdit ? '$_apiUrl/branches/$id' : '$_apiUrl/branches';
      final response = isEdit
          ? await http.put(Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(branchData))
          : await http.post(Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(branchData));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(isEdit ? 'Cập nhật chi nhánh thành công!' : 'Tạo chi nhánh mới thành công!');
        _fetchBranches();
      } else {
        final body = json.decode(response.body);
        _showSnackBar(body['message'] ?? 'Thao tác thất bại!', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối máy chủ: $e', isError: true);
    }
  }

  // ==================== 2. API: RECIPE CONFIG (6.2) ====================
  Future<void> _fetchRecipes() async {
    setState(() => _isLoadingRecipes = true);
    try {
      final response = await http.get(Uri.parse('$_apiUrl/recipes'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          setState(() => _recipes = body['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải định lượng công thức: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRecipes = false);
    }
  }

  Future<void> _saveRecipe(Map<String, dynamic> recipeData) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/recipes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(recipeData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Cập nhật định lượng công thức thành công!');
        _fetchRecipes();
      } else {
        _showSnackBar('Không thể lưu công thức', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi hệ thống: $e', isError: true);
    }
  }

  // ==================== 3. API: LOCAL INVENTORY (5.1) ====================
  Future<void> _fetchInventories() async {
    setState(() => _isLoadingInventories = true);
    try {
      final response = await http.get(Uri.parse('$_apiUrl/branch-inventories'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          setState(() => _inventories = body['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải kho chi nhánh: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInventories = false);
    }
  }

  Future<void> _updateInventory(Map<String, dynamic> invData) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/branch-inventories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Cập nhật tồn kho thành công!');
        _fetchInventories();
      } else {
        _showSnackBar('Cập nhật thất bại', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: $e', isError: true);
    }
  }

  // ==================== 4. API: BRANCH REPORT (5.2) ====================
  Future<void> _fetchBranchReport(int branchId, String period) async {
    setState(() => _isLoadingBranchReport = true);
    try {
      final response = await http.get(
          Uri.parse('$_apiUrl/reports/branch/$branchId?period=$period'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          setState(() => _branchReport = body['data']);
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải báo cáo chi nhánh: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBranchReport = false);
    }
  }

  // ==================== 5. API: CONSOLIDATED REPORT (6.4) ====================
  Future<void> _fetchConsolidatedReport() async {
    setState(() => _isLoadingConsolidated = true);
    try {
      final response = await http.get(Uri.parse('$_apiUrl/reports/consolidated'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          setState(() => _consolidatedReport = body['data']);
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải báo cáo toàn chuỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoadingConsolidated = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================== MAIN BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latteBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.coffee, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('QUẢN TRỊ CAFE SHOP',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Hệ thống Quản lý Chuỗi & Báo cáo',
                    style: TextStyle(fontSize: 11, color: AppColors.warmAmber)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _fetchAllData,
          ),
          IconButton(
            icon: const Icon(Icons.settings_remote),
            tooltip: 'Đổi IP API Server',
            onPressed: _showConfigApiDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.warmAmber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.warmAmber.withAlpha(178),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.store), text: '6.1 Chuỗi Chi Nhánh'),
            Tab(icon: Icon(Icons.receipt_long), text: '6.2 Công Thức/Định Lượng'),
            Tab(icon: Icon(Icons.inventory_2), text: '5.1 Kho Chi Nhánh'),
            Tab(icon: Icon(Icons.analytics), text: '5.2 Báo Cáo Chi Nhánh'),
            Tab(icon: Icon(Icons.pie_chart), text: '6.4 Báo Cáo Hợp Nhất'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBranchManagementTab(),
          _buildRecipeConfigTab(),
          _buildLocalInventoryTab(),
          _buildBranchReportTab(),
          _buildConsolidatedReportTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: 6.1 QUẢN LÝ CHUỖI CHI NHÁNH ====================
  Widget _buildBranchManagementTab() {
    if (_isLoadingBranches) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quản lý Chuỗi chi nhánh (${_branches.length})',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espressoDark)),
                    const Text('Chức năng 6.1 - Thêm, sửa, đóng/mở cửa chi nhánh',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm chi nhánh'),
                onPressed: () => _showBranchFormDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_branches.isEmpty)
            _buildEmptyState('Chưa có chi nhánh nào trong hệ thống')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _branches.length,
              itemBuilder: (context, index) {
                final b = _branches[index];
                final isOpen = b['status'] == 'Open';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: isOpen
                          ? AppColors.successGreen.withAlpha(38)
                          : AppColors.errorRed.withAlpha(38),
                      child: Icon(
                        Icons.storefront,
                        color: isOpen ? AppColors.successGreen : AppColors.errorRed,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          b['branchName'] ?? 'Chi nhánh chưa đặt tên',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isOpen ? 'Hoạt động' : 'Đóng cửa',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  b['address'] ?? 'Chưa cập nhật địa chỉ',
                                  style: const TextStyle(
                                      color: AppColors.textDark, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Giờ mở cửa: ${b['openingTime'] ?? '07:00'} - ${b['closingTime'] ?? '22:30'}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.coffeePrimary),
                      onPressed: () => _showBranchFormDialog(branch: b),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Dialog Thêm/Sửa Chi nhánh
  void _showBranchFormDialog({Map<String, dynamic>? branch}) {
    final isEdit = branch != null;
    final nameCtrl = TextEditingController(text: branch?['branchName'] ?? '');
    final addressCtrl = TextEditingController(text: branch?['address'] ?? '');
    final latCtrl =
        TextEditingController(text: (branch?['latitude'] ?? 10.776889).toString());
    final lngCtrl =
        TextEditingController(text: (branch?['longitude'] ?? 106.700806).toString());
    final openCtrl =
        TextEditingController(text: branch?['openingTime'] ?? '07:00:00');
    final closeCtrl =
        TextEditingController(text: branch?['closingTime'] ?? '22:30:00');
    String status = branch?['status'] ?? 'Open';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Chỉnh sửa Chi nhánh' : 'Thêm Chi nhánh mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên Chi nhánh *'),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ *'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: openCtrl,
                      decoration: const InputDecoration(labelText: 'Giờ mở (HH:mm:ss)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: closeCtrl,
                      decoration: const InputDecoration(labelText: 'Giờ đóng (HH:mm:ss)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'Open', child: Text('Đang mở cửa (Open)')),
                  DropdownMenuItem(value: 'Closed', child: Text('Đóng cửa (Closed)')),
                ],
                onChanged: (val) {
                  if (val != null) status = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coffeePrimary,
                foregroundColor: Colors.white),
            onPressed: () {
              final payload = {
                if (isEdit) 'id': branch['id'],
                'branchName': nameCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'latitude': double.tryParse(latCtrl.text) ?? 10.776889,
                'longitude': double.tryParse(lngCtrl.text) ?? 106.700806,
                'openingTime': openCtrl.text.trim(),
                'closingTime': closeCtrl.text.trim(),
                'status': status,
              };
              Navigator.pop(context);
              _saveBranch(payload, id: branch?['id']);
            },
            child: Text(isEdit ? 'Lưu thay đổi' : 'Tạo mới'),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: 6.2 THIẾT LẬP CÔNG THỨC ====================
  Widget _buildRecipeConfigTab() {
    if (_isLoadingRecipes) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Định lượng Công thức Nguyên liệu',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espressoDark)),
                    Text('Chức năng 6.2 - Định lượng chuẩn để tự động trừ kho',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.tune),
                label: const Text('Khai báo định lượng'),
                onPressed: () => _showRecipeFormDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recipes.isEmpty)
            _buildEmptyState('Chưa có công thức/định lượng nguyên liệu nào')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final r = _recipes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.warmAmber,
                      child: Icon(Icons.science, color: AppColors.espressoDark),
                    ),
                    title: Text(
                      'Món ID: ${r['menuItemId'] ?? r['id']?['menuItemID'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'Nguyên liệu ID: ${r['ingredientId'] ?? r['id']?['ingredientID'] ?? 'N/A'} | Định lượng chuẩn: ${r['standardQuantity'] ?? 0.0} (gram/ml)'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.coffeePrimary),
                      onPressed: () => _showRecipeFormDialog(recipe: r),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showRecipeFormDialog({Map<String, dynamic>? recipe}) {
    final menuItemCtrl = TextEditingController(
        text: (recipe?['menuItemId'] ?? recipe?['id']?['menuItemID'] ?? '').toString());
    final ingredientCtrl = TextEditingController(
        text: (recipe?['ingredientId'] ?? recipe?['id']?['ingredientID'] ?? '').toString());
    final qtyCtrl = TextEditingController(
        text: (recipe?['standardQuantity'] ?? '30.0').toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khai báo Định lượng Nguyên liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: menuItemCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã Món ăn (MenuItemID) *'),
            ),
            TextField(
              controller: ingredientCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã Nguyên liệu (IngredientID) *'),
            ),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Số lượng chuẩn (StandardQuantity - gram/ml) *'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coffeePrimary,
                foregroundColor: Colors.white),
            onPressed: () {
              final payload = {
                'id': {
                  'menuItemID': int.tryParse(menuItemCtrl.text) ?? 1,
                  'ingredientID': int.tryParse(ingredientCtrl.text) ?? 1,
                },
                'standardQuantity': double.tryParse(qtyCtrl.text) ?? 30.0,
              };
              Navigator.pop(context);
              _saveRecipe(payload);
            },
            child: const Text('Lưu định lượng'),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: 5.1 QUẢN LÝ KHO CHI NHÁNH ====================
  Widget _buildLocalInventoryTab() {
    if (_isLoadingInventories) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Tồn kho Chi nhánh (Local Inventory)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espressoDark)),
                    Text('Chức năng 5.1 - Theo dõi & Cập nhật kho nguyên liệu',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Nhập/Điều chỉnh kho'),
                onPressed: () => _showInventoryFormDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_inventories.isEmpty)
            _buildEmptyState('Chưa có dữ liệu tồn kho chi nhánh')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _inventories.length,
              itemBuilder: (context, index) {
                final inv = _inventories[index];
                final currentStock = (inv['currentStock'] ?? inv['quantityAvailable'] ?? 0).toDouble();
                final safeThreshold = (inv['safeThreshold'] ?? 10).toDouble();
                final isLowStock = currentStock < safeThreshold;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLowStock
                          ? AppColors.errorRed.withAlpha(38)
                          : AppColors.successGreen.withAlpha(38),
                      child: Icon(
                        isLowStock ? Icons.warning_amber : Icons.inventory,
                        color: isLowStock ? AppColors.errorRed : AppColors.successGreen,
                      ),
                    ),
                    title: Text(
                      'Chi nhánh ID: ${inv['branchID']?['id'] ?? inv['branchId'] ?? 'N/A'} | NL ID: ${inv['ingredientID']?['id'] ?? inv['ingredientId'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'Tồn kho hiện tại: $currentStock | Ngưỡng an toàn: $safeThreshold'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLowStock ? AppColors.errorRed : AppColors.successGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isLowStock ? 'CẢNH BÁO THẮT KHO' : 'ĐỦ HÀNG',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showInventoryFormDialog() {
    final branchCtrl = TextEditingController(text: '1');
    final ingredientCtrl = TextEditingController(text: '1');
    final stockCtrl = TextEditingController(text: '500.0');
    final thresholdCtrl = TextEditingController(text: '50.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật Tồn kho Chi nhánh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: branchCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã Chi nhánh (BranchID) *'),
            ),
            TextField(
              controller: ingredientCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã Nguyên liệu (IngredientID) *'),
            ),
            TextField(
              controller: stockCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Số lượng tồn mới (CurrentStock) *'),
            ),
            TextField(
              controller: thresholdCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ngưỡng cảnh báo an toàn (SafeThreshold) *'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coffeePrimary,
                foregroundColor: Colors.white),
            onPressed: () {
              final payload = {
                'branchID': {'id': int.tryParse(branchCtrl.text) ?? 1},
                'ingredientID': {'id': int.tryParse(ingredientCtrl.text) ?? 1},
                'currentStock': double.tryParse(stockCtrl.text) ?? 500.0,
                'safeThreshold': double.tryParse(thresholdCtrl.text) ?? 50.0,
              };
              Navigator.pop(context);
              _updateInventory(payload);
            },
            child: const Text('Cập nhật Kho'),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: 5.2 BÁO CÁO KINH DOANH CHI NHÁNH ====================
  Widget _buildBranchReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Báo cáo Doanh thu Chi nhánh',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espressoDark)),
          const Text('Chức năng 5.2 - Xem tổng doanh thu & món bán chạy tại cửa hàng',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),

          // Filters Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedBranchIdForReport,
                      decoration:
                          const InputDecoration(labelText: 'Chọn Chi nhánh'),
                      items: _branches.isEmpty
                          ? [
                              const DropdownMenuItem(
                                  value: 1, child: Text('Chi nhánh Chi nhánh #1'))
                            ]
                          : _branches.map((b) {
                              return DropdownMenuItem<int>(
                                value: b['id'] ?? 1,
                                child: Text(
                                    b['branchName'] ?? 'Chi nhánh #${b['id']}'),
                              );
                            }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedBranchIdForReport = val);
                          _fetchBranchReport(val, _selectedReportPeriod);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedReportPeriod,
                      decoration:
                          const InputDecoration(labelText: 'Thời gian'),
                      items: const [
                        DropdownMenuItem(value: 'TODAY', child: Text('Hôm nay')),
                        DropdownMenuItem(value: 'WEEK', child: Text('Tuần này')),
                        DropdownMenuItem(value: 'MONTH', child: Text('Tháng này')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedReportPeriod = val);
                          _fetchBranchReport(_selectedBranchIdForReport, val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingBranchReport)
            const Center(child: CircularProgressIndicator())
          else if (_branchReport == null)
            _buildEmptyState('Không có dữ liệu báo cáo cho chi nhánh này')
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Doanh thu',
                    '${_formatCurrency(_branchReport!['revenue'] ?? 0)} đ',
                    Icons.monetization_on,
                    AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Tổng số đơn',
                    '${_branchReport!['ordersCount'] ?? 0} đơn',
                    Icons.shopping_bag,
                    AppColors.coffeePrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Đơn trung bình',
                    '${_formatCurrency(_branchReport!['avgOrder'] ?? 0)} đ',
                    Icons.analytics,
                    AppColors.accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Top Sản phẩm bán chạy tại Chi nhánh',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espressoDark)),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (_branchReport!['topProducts'] as List? ?? []).length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final p = _branchReport!['topProducts'][index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.coffeePrimary,
                      child: Text('${index + 1}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(p['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Đã bán: ${p['sold'] ?? 0} ly'),
                    trailing: Text(
                      '${((p['percent'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.coffeePrimary),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== TAB 5: 6.4 BÁO CÁO HỢP NHẤT TOÀN CHUỖI ====================
  Widget _buildConsolidatedReportTab() {
    if (_isLoadingConsolidated) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Báo cáo Hợp nhất Toàn chuỗi',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espressoDark)),
          const Text('Chức năng 6.4 - Dashboard Báo cáo hợp nhất dành cho Ban Quản Trị',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),

          if (_consolidatedReport == null)
            _buildEmptyState('Không thể tải báo cáo hợp nhất')
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.coffeeGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TỔNG DOANH THU TOÀN HỆ THỐNG',
                      style: TextStyle(
                          color: AppColors.warmAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(_consolidatedReport!['totalRevenue'] ?? 0)} VNĐ',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Tổng đơn toàn chuỗi: ${_consolidatedReport!['totalOrders'] ?? 0} đơn',
                          style: const TextStyle(color: Colors.white70)),
                      Text(
                          'Trung bình/Đơn: ${_formatCurrency(_consolidatedReport!['avgOrderValue'] ?? 0)} đ',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Số Chi nhánh',
                    '${_branches.length} cửa hàng',
                    Icons.storefront,
                    AppColors.coffeePrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Chi nhánh đang mở',
                    '${_branches.where((b) => b['status'] == 'Open').length} mở cửa',
                    Icons.check_circle,
                    AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper UI Elements
  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espressoDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox, size: 48, color: AppColors.warmAmber),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  void _showConfigApiDialog() {
    final ctrl = TextEditingController(text: _apiUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình API Server Base URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              hintText: 'http://10.0.2.2:8080/api hoặc http://localhost:8080/api'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              setState(() => _apiUrl = ctrl.text.trim());
              Navigator.pop(context);
              _fetchAllData();
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final n = (amount is num) ? amount.toInt() : int.tryParse(amount.toString()) ?? 0;
    return n.toString().replaceAllRegExp(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
  }
}

extension StringFormatExtension on String {
  String replaceAllRegExp(RegExp regex, String replacement) {
    return replaceAllMapped(regex, (match) => replacement);
  }
}
