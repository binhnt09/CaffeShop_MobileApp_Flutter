import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/widgets/coffee_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _timePeriod = 'MONTH'; // TODAY, WEEK, MONTH, YEAR
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final List<MockBranch> _branches = MockData.branches;

  // Consolidated statistics based on selected period
  double get _chainRevenue => _timePeriod == 'TODAY' ? 62400000 : _timePeriod == 'WEEK' ? 418000000 : _timePeriod == 'MONTH' ? 1780000000 : 21400000000;
  int get _chainOrders => _timePeriod == 'TODAY' ? 710 : _timePeriod == 'WEEK' ? 4750 : _timePeriod == 'MONTH' ? 20200 : 243000;
  int get _activeBranches => _branches.length;
  double get _chainGrowth => 8.4; // % growth

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download_done, color: Colors.white),
            SizedBox(width: 8),
            Text('Đã xuất báo cáo doanh thu chuỗi định dạng Excel thành công!'),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showBranchDialog({MockBranch? branchToEdit}) {
    final nameController = TextEditingController(text: branchToEdit?.name ?? '');
    final addressController = TextEditingController(text: branchToEdit?.address ?? '');
    final openTimeController = TextEditingController(text: branchToEdit?.openTime ?? '07:00');
    final closeTimeController = TextEditingController(text: branchToEdit?.closeTime ?? '22:00');
    bool isOpen = branchToEdit?.isOpen ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(branchToEdit == null ? 'Thêm Chi Nhánh Mới' : 'Sửa Chi Nhánh', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tên chi nhánh'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Địa chỉ'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: openTimeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Giờ mở cửa'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: closeTimeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Giờ đóng cửa'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trạng thái hoạt động:', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: isOpen,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            setModalState(() => isOpen = val);
                          },
                        ),
                      ],
                    ),
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
                    final name = nameController.text.trim();
                    final address = addressController.text.trim();
                    if (name.isEmpty || address.isEmpty) return;

                    setState(() {
                      if (branchToEdit == null) {
                        _branches.add(
                          MockBranch(
                            id: 'br_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            address: address,
                            latitude: 10.7825,
                            longitude: 106.6970,
                            openTime: openTimeController.text.trim(),
                            closeTime: closeTimeController.text.trim(),
                            isOpen: isOpen,
                            distanceKm: 1.0,
                          ),
                        );
                      } else {
                        final idx = _branches.indexWhere((b) => b.id == branchToEdit.id);
                        if (idx >= 0) {
                          _branches[idx] = MockBranch(
                            id: branchToEdit.id,
                            name: name,
                            address: address,
                            latitude: branchToEdit.latitude,
                            longitude: branchToEdit.longitude,
                            openTime: openTimeController.text.trim(),
                            closeTime: closeTimeController.text.trim(),
                            isOpen: isOpen,
                            distanceKm: branchToEdit.distanceKm,
                          );
                        }
                      }
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cập nhật chi nhánh $name thành công!'), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
                  child: Text(branchToEdit == null ? 'THÊM MỚI' : 'CẬP NHẬT'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Central Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: AppColors.accent),
            tooltip: 'Quản lý tài khoản',
            onPressed: () => context.go('/admin/users'),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu, color: AppColors.accent),
            tooltip: 'Cấu hình thực đơn',
            onPressed: () => context.go('/admin/menu'),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long, color: AppColors.accent),
            tooltip: 'Định lượng công thức',
            onPressed: () => context.go('/admin/recipes'),
          ),
          IconButton(
            icon: const Icon(Icons.storefront, color: AppColors.accent),
            tooltip: 'Mạng lưới chi nhánh',
            onPressed: () => context.go('/admin/branches'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppColors.error),
            tooltip: 'Đăng xuất',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BÁO CÁO HỢP NHẤT TOÀN CHUỖI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 12)),
                DropdownButton<String>(
                  value: _timePeriod,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _timePeriod = val);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'TODAY', child: Text('Hôm nay')),
                    DropdownMenuItem(value: 'WEEK', child: Text('Tuần này')),
                    DropdownMenuItem(value: 'MONTH', child: Text('Tháng này')),
                    DropdownMenuItem(value: 'YEAR', child: Text('Năm nay')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Consolidated metrics cards
            Row(
              children: [
                _buildMetricCard('Doanh thu chuỗi', currencyFormat.format(_chainRevenue), Colors.green),
                const SizedBox(width: 10),
                _buildMetricCard('Tổng đơn bán', '$_chainOrders đơn', Colors.blue),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricCard('Cửa hàng hoạt động', '$_activeBranches chi nhánh', AppColors.accent),
                const SizedBox(width: 10),
                _buildMetricCard('Tăng trưởng chuỗi', '+$_chainGrowth%', Colors.orange),
              ],
            ),
            const SizedBox(height: 28),

            // Bar Chart - Branch revenue comparisons (fl_chart)
            _buildSectionTitle('SO SÁNH HIỆU SUẤT DOANH THU CÁC CHI NHÁNH'),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const labels = ['HBT', 'NĐC', 'LQĐ', 'CMT8', 'PXL'];
                          if (val >= 0 && val < labels.length) {
                            return Text(labels[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.white54));
                          }
                          return const Text('');
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 4.8, color: Colors.green, width: 16, borderRadius: BorderRadius.circular(2))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3.9, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(2))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3.5, color: Colors.orange, width: 16, borderRadius: BorderRadius.circular(2))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 2.9, color: Colors.red, width: 16, borderRadius: BorderRadius.circular(2))]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 2.7, color: AppColors.accent, width: 16, borderRadius: BorderRadius.circular(2))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Pie Chart - Revenue contribution splits (fl_chart)
            _buildSectionTitle('TỶ LỆ ĐÓNG GÓP DOANH THU TOÀN CHUỖI'),
            const SizedBox(height: 8),
            Container(
              height: 180,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(value: 27, title: '27%', color: Colors.green, radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          PieChartSectionData(value: 22, title: '22%', color: Colors.blue, radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          PieChartSectionData(value: 20, title: '20%', color: Colors.orange, radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          PieChartSectionData(value: 16, title: '16%', color: Colors.red, radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          PieChartSectionData(value: 15, title: '15%', color: AppColors.accent, radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendRow('Hai Bà Trưng', Colors.green),
                          _buildLegendRow('Nguyễn Đình Chiểu', Colors.blue),
                          _buildLegendRow('Lê Quý Đôn', Colors.orange),
                          _buildLegendRow('Cách Mạng T8', Colors.red),
                          _buildLegendRow('Phan Xích Long', AppColors.accent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Branch Performance Ranking Table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('DANH SÁCH & QUẢN LÝ CHI NHÁNH'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_business, size: 18, color: AppColors.accent),
                      onPressed: () => _showBranchDialog(),
                      tooltip: 'Thêm chi nhánh mới',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, size: 18, color: AppColors.accent),
                      onPressed: _exportReport,
                      tooltip: 'Xuất báo cáo Excel',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Chi nhánh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Giờ hoạt động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                  rows: _branches.map((b) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: b.isOpen ? AppColors.success : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                        DataCell(Text('${b.openTime} - ${b.closeTime}', style: const TextStyle(fontSize: 11))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (b.isOpen ? AppColors.success : AppColors.error).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b.isOpen ? 'ĐANG MỞ' : 'ĐÓNG CỬA',
                              style: TextStyle(color: b.isOpen ? AppColors.success : AppColors.error, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white60, size: 16),
                                onPressed: () => _showBranchDialog(branchToEdit: b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _branches.removeWhere((x) => x.id == b.id);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.white38)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
