import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';

class KDSKitchenScreen extends StatefulWidget {
  const KDSKitchenScreen({super.key});

  @override
  State<KDSKitchenScreen> createState() => _KDSKitchenScreenState();
}

class _KDSKitchenScreenState extends State<KDSKitchenScreen> {
  final List<MockOrder> _allOrders = MockData.orderHistory;
  Timer? _orderSimulatorTimer;
  Timer? _timerTicker;
  
  // Track order ages in seconds for urgency levels
  final Map<String, int> _orderAges = {};

  @override
  void initState() {
    super.initState();
    _initOrderAges();
    _startTimerTicker();
    _startSimulatedNewOrders();
  }

  @override
  void dispose() {
    _orderSimulatorTimer?.cancel();
    _timerTicker?.cancel();
    super.dispose();
  }

  void _initOrderAges() {
    for (var o in _allOrders) {
      // Calculate approximate starting ages in seconds
      _orderAges[o.id] = DateTime.now().difference(o.createdAt).inSeconds;
    }
  }

  void _startTimerTicker() {
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        for (var key in _orderAges.keys) {
          _orderAges[key] = (_orderAges[key] ?? 0) + 1;
        }
      });
    });
  }

  void _startSimulatedNewOrders() {
    // Periodically generate new client orders to make KDS look interactive and alive
    _orderSimulatorTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (!mounted) return;
      
      // Select a random product
      final randomProductIndex = (DateTime.now().second) % MockData.products.length;
      final product = MockData.products[randomProductIndex];
      
      final newCartItem = MockCartItem(
        id: const Uuid().v4(),
        product: product,
        size: 'L',
        selectedToppings: const [],
        quantity: 1,
      );

      final newOrderCode = 'CF-${1000 + DateTime.now().second * 9}';
      final newSimOrder = MockOrder(
        id: 'ord_sim_${DateTime.now().millisecondsSinceEpoch}',
        orderCode: newOrderCode,
        branchName: MockData.branches[0].name,
        items: [newCartItem],
        totalAmount: product.basePrice + 10000,
        discountAmount: 0,
        finalAmount: product.basePrice + 10000,
        paymentMethod: 'VNPAY',
        status: 'PENDING',
        createdAt: DateTime.now(),
        source: 'MOBILE_APP',
      );

      setState(() {
        MockData.orderHistory.insert(0, newSimOrder);
        _orderAges[newSimOrder.id] = 0;
      });

      // Sound notification simulation via snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.ring_volume, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('🔔 Kính coong! Đơn hàng mới $newOrderCode vừa được gửi vào bếp.'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  void _changeOrderStatus(MockOrder order, String newStatus) {
    setState(() {
      final index = MockData.orderHistory.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        final updatedOrder = MockOrder(
          id: order.id,
          orderCode: order.orderCode,
          branchName: order.branchName,
          items: order.items,
          totalAmount: order.totalAmount,
          discountAmount: order.discountAmount,
          finalAmount: order.finalAmount,
          paymentMethod: order.paymentMethod,
          status: newStatus,
          createdAt: order.createdAt,
          source: order.source,
        );
        MockData.orderHistory[index] = updatedOrder;
      }
    });
  }

  List<MockOrder> _getOrdersByStatus(List<String> statuses) {
    return MockData.orderHistory.where((o) => statuses.contains(o.status)).toList();
  }

  String _formatDuration(int totalSecs) {
    final int min = totalSecs ~/ 60;
    final int sec = totalSecs % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color _getUrgencyColor(int ageSecs) {
    if (ageSecs >= 300) return AppColors.error; // Red if > 5 minutes
    if (ageSecs >= 180) return AppColors.warning; // Orange if > 3 minutes
    return AppColors.success; // Green otherwise
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _getOrdersByStatus(['PENDING', 'CONFIRMED']);
    final brewingOrders = _getOrdersByStatus(['BREWING']);
    final readyOrders = _getOrdersByStatus(['READY']);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KDS - Quản Lý Bếp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Chờ (${pendingOrders.length})'),
              Tab(text: 'Đang Làm (${brewingOrders.length})'),
              Tab(text: 'Sẵn Sàng (${readyOrders.length})'),
            ],
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: AppColors.error),
              tooltip: 'Thoát KDS',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildKDSColumn('⏳ ĐƠN CHỜ PHA CHẾ', pendingOrders, 'START'),
            _buildKDSColumn('🔥 ĐANG PHA CHẾ', brewingOrders, 'FINISH'),
            _buildKDSColumn('✅ ĐỒ UỐNG ĐÃ SẴN SÀNG', readyOrders, 'DELIVER'),
          ],
        ),
      ),
    );
  }

  Widget _buildKDSColumn(String title, List<MockOrder> orders, String actionType) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.accent),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${orders.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Cards list
          Expanded(
            child: orders.isEmpty
                ? Center(child: Text('Trống', style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 14)))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final ageSecs = _orderAges[order.id] ?? 0;
                      final timerColor = _getUrgencyColor(ageSecs);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order code, source, and timer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderCode,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                  Row(
                                    children: [
                                      // Timer duration
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: timerColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.timer, size: 10, color: timerColor),
                                            const SizedBox(width: 2),
                                            Text(
                                              _formatDuration(ageSecs),
                                              style: TextStyle(color: timerColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Source label
                                      Icon(
                                        order.source == 'POS' ? Icons.point_of_sale : Icons.phone_android,
                                        size: 14,
                                        color: Colors.white30,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(),
                              
                              // List drinks and toppings
                              ...order.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ${item.product.name} (x${item.quantity})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                      ),
                                      Text(
                                        '  Size ${item.size} • Đường ${item.sugarLevel}% • Đá ${item.iceLevel}%',
                                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                                      ),
                                      if (item.selectedToppings.isNotEmpty)
                                        Text(
                                          '  Toppings: ${item.selectedToppings.map((t) => t.name).join(", ")}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.accent),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              
                              const SizedBox(height: 12),
                              
                              // Action transitions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (actionType == 'START')
                                    ElevatedButton(
                                      onPressed: () => _changeOrderStatus(order, 'BREWING'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('PHA CHẾ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  if (actionType == 'FINISH')
                                    ElevatedButton(
                                      onPressed: () => _changeOrderStatus(order, 'READY'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: AppColors.background,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('XONG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  if (actionType == 'DELIVER')
                                    ElevatedButton(
                                      onPressed: () => _changeOrderStatus(order, 'COMPLETED'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('GIAO KHÁCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                ],
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
    );
  }
}
