import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _timeFilter = 'WEEK'; // TODAY, WEEK, MONTH
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Dynamic KPI values based on filter selection
  double get _revenue => _timeFilter == 'TODAY' ? 12500000 : _timeFilter == 'WEEK' ? 84000000 : 362000000;
  int get _ordersCount => _timeFilter == 'TODAY' ? 143 : _timeFilter == 'WEEK' ? 950 : 4100;
  double get _avgOrder => _revenue / _ordersCount;
  String get _topProduct => 'Bạc Xỉu Đá Caramel';

  final List<Map<String, dynamic>> _topProducts = [
    {'name': 'Bạc Xỉu Đá Caramel', 'sold': 324, 'percent': 0.85},
    {'name': 'Cà Phê Sữa Đá Sài Gòn', 'sold': 288, 'percent': 0.76},
    {'name': 'Trà Đào Cam Sả', 'sold': 210, 'percent': 0.55},
    {'name': 'Trà Sen Vàng Hạt Sen', 'sold': 185, 'percent': 0.48},
    {'name': 'Tiramisu Cacao', 'sold': 95, 'percent': 0.25},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Manager Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory, color: AppColors.accent),
            tooltip: 'Quản lý kho',
            onPressed: () => context.go('/manager/inventory'),
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
            // Header store metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CHI NHÁNH QUẢN LÝ', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      MockData.branches[0].name.replaceAll('CaffeShop ', ''),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Time frame filter tabs
                DropdownButton<String>(
                  value: _timeFilter,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _timeFilter = val);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'TODAY', child: Text('Hôm nay')),
                    DropdownMenuItem(value: 'WEEK', child: Text('Tuần này')),
                    DropdownMenuItem(value: 'MONTH', child: Text('Tháng này')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Grid Cards (2x2)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildKPICard('Doanh thu', currencyFormat.format(_revenue), Icons.monetization_on, Colors.green),
                _buildKPICard('Số đơn phục vụ', '$_ordersCount đơn', Icons.shopping_basket, Colors.blue),
                _buildKPICard('Trung bình/Đơn', currencyFormat.format(_avgOrder), Icons.analytics, Colors.purple),
                _buildKPICard('Món bán chạy', _topProduct, Icons.star, AppColors.accent),
              ],
            ),
            const SizedBox(height: 28),

            // Line chart - Revenue trend (fl_chart)
            _buildSectionTitle('XU HƯỚNG DOANH THU (7 NGÀY GẦN NHẤT)'),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                          if (val >= 0 && val < days.length) {
                            return Text(days[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.white30));
                          }
                          return const Text('');
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 10),
                        FlSpot(1, 12),
                        FlSpot(2, 8),
                        FlSpot(3, 14),
                        FlSpot(4, 15),
                        FlSpot(5, 22),
                        FlSpot(6, 18),
                      ],
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Bar chart - Shift sales comparisons
            _buildSectionTitle('THỐNG KÊ DOANH THU THEO CA LÀM'),
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const shifts = ['Ca Sáng', 'Ca Chiều', 'Ca Tối'];
                          if (val >= 0 && val < shifts.length) {
                            return Text(shifts[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.white54));
                          }
                          return const Text('');
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3.5, color: Colors.orange, width: 24, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5.2, color: Colors.blue, width: 24, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 7.8, color: AppColors.primaryLight, width: 24, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Top Products listing
            _buildSectionTitle('TOP 5 MÓN BÁN CHẠY NHẤT'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: _topProducts.map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${p['sold']} ly', style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: p['percent'] as double,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.white30)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: title == 'Món bán chạy' ? 12 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
