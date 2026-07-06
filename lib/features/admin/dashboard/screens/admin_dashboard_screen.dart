import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/coffee_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _timePeriod = 'MONTH'; // TODAY, WEEK, MONTH, YEAR
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Consolidated statistics based on selected period
  double get _chainRevenue => _timePeriod == 'TODAY' ? 62400000 : _timePeriod == 'WEEK' ? 418000000 : _timePeriod == 'MONTH' ? 1780000000 : 21400000000;
  int get _chainOrders => _timePeriod == 'TODAY' ? 710 : _timePeriod == 'WEEK' ? 4750 : _timePeriod == 'MONTH' ? 20200 : 243000;
  int get _activeBranches => 5;
  double get _chainGrowth => 8.4; // % growth

  final List<Map<String, dynamic>> _branchesRanking = [
    {'name': 'Hai Bà Trưng', 'revenue': 480000000, 'orders': 5400, 'growth': 12.5, 'isOpen': true},
    {'name': 'Nguyễn Đình Chiểu', 'revenue': 390000000, 'orders': 4400, 'growth': 6.2, 'isOpen': true},
    {'name': 'Lê Quý Đôn', 'revenue': 350000000, 'orders': 4000, 'growth': 8.8, 'isOpen': true},
    {'name': 'Cách Mạng T8', 'revenue': 290000000, 'orders': 3300, 'growth': -2.4, 'isOpen': false},
    {'name': 'Phan Xích Long', 'revenue': 270000000, 'orders': 3100, 'growth': 5.0, 'isOpen': true},
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Central Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu, color: AppColors.accent),
            tooltip: 'Cấu hình thực đơn',
            onPressed: () => context.go('/admin/menu'),
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
                const Text('BÁO CÁO HỢP NHẤT TOÀN CHUỖI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13)),
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
                          const branches = ['HBT', 'NĐC', 'LQĐ', 'CMT8', 'PXL'];
                          if (val >= 0 && val < branches.length) {
                            return Text(branches[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.white54));
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
                _buildSectionTitle('BẢNG XẾP HẠNG CHI NHÁNH'),
                IconButton(
                  icon: const Icon(Icons.download, size: 18, color: AppColors.accent),
                  onPressed: _exportReport,
                  tooltip: 'Xuất báo cáo Excel',
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
                    DataColumn(label: Text('Doanh thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataColumn(label: Text('Tăng trưởng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                  rows: _branchesRanking.map((b) {
                    final growth = b['growth'] as double;
                    final isPositive = growth >= 0;

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
                                  color: b['isOpen'] as bool ? AppColors.success : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(b['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                        DataCell(Text(currencyFormat.format(b['revenue']), style: const TextStyle(fontSize: 11))),
                        DataCell(Text('${b['orders']}', style: const TextStyle(fontSize: 11))),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                color: isPositive ? AppColors.success : AppColors.error,
                                size: 10,
                              ),
                              Text(
                                '${isPositive ? "+" : ""}$growth%',
                                style: TextStyle(color: isPositive ? AppColors.success : AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 10, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.white30)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
