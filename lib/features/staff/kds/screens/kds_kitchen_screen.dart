import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/stomp_service.dart';
import '../../../auth/bloc/auth_bloc.dart';

class KDSKitchenScreen extends StatefulWidget {
  const KDSKitchenScreen({super.key});

  @override
  State<KDSKitchenScreen> createState() => _KDSKitchenScreenState();
}

class _KDSKitchenScreenState extends State<KDSKitchenScreen> {
  final List<MockOrder> _allOrders = MockData.orderHistory;
  Timer? _orderSimulatorTimer;
  Timer? _timerTicker;
  StompUnsubscribe? _wsUnsubscribe;
  
  // Track order ages in seconds for urgency levels
  final Map<String, int> _orderAges = {};

  @override
  void initState() {
    super.initState();
    _initOrderAges();
    _startTimerTicker();
    _connectKDSWebSocket();
  }

  @override
  void dispose() {
    _orderSimulatorTimer?.cancel();
    _timerTicker?.cancel();
    _wsUnsubscribe?.call();
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

  void _connectKDSWebSocket() {
    final token = AuthBloc.currentUser?.token;
    final branchId = AuthBloc.currentUser?.branchId ?? '1';
    if (token == null) {
      _startSimulatedNewOrders();
      return;
    }

    StompService.instance.connect(
      token: token,
      onConnected: () {
        _wsUnsubscribe = StompService.instance.subscribeBranchOrders(branchId, (data) {
          if (!mounted) return;
          final orderCode = data['orderCode']?.toString() ?? 'CF-${1000 + DateTime.now().second * 9}';
          final orderId = data['orderId']?.toString() ?? 'ord_ws_${DateTime.now().millisecondsSinceEpoch}';
          
          final newWsOrder = MockOrder(
            id: orderId,
            orderCode: orderCode,
            branchName: MockData.branches[0].name,
            items: const [],
            totalAmount: 45000,
            discountAmount: 0,
            finalAmount: 45000,
            paymentMethod: 'PAYOS',
            status: data['status']?.toString() ?? 'PENDING',
            createdAt: DateTime.now(),
            source: 'MOBILE_APP',
          );

          setState(() {
            MockData.orderHistory.insert(0, newWsOrder);
            _orderAges[newWsOrder.id] = 0;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.ring_volume, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('🔔 Kính coong! Đơn hàng mới $orderCode vừa được gửi vào bếp.'),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      },
    );
  }

  void _startSimulatedNewOrders() {
    // Periodically generate new client orders to make KDS look interactive and alive
    _orderSimulatorTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (!mounted) return;
      
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

  Future<void> _changeOrderStatus(MockOrder order, String newStatus) async {
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

    final token = AuthBloc.currentUser?.token;
    if (token != null) {
      try {
        await ApiService.instance.updateOrderStatus(order.id, newStatus, token);
      } catch (e) {
        print('Error updating status via API: $e');
      }
    }
  }

  List<MockOrder> _getOrdersByStatus(List<String> statuses) {
    final lower = statuses.map((s) => s.toLowerCase()).toList();
    return MockData.orderHistory.where((o) => lower.contains(o.status.toLowerCase())).toList();
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
    final pendingOrders = _getOrdersByStatus(['PENDING', 'Pending', 'CONFIRMED', 'Confirmed']);
    final brewingOrders = _getOrdersByStatus(['BREWING', 'Preparing', 'Brewing']);
    final readyOrders = _getOrdersByStatus(['READY', 'Ready']);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KDS - Quản Lý Bếp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Quay lại POS',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/pos');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.replay, color: AppColors.accent),
              tooltip: 'Tua về: Trở về trạng thái Chờ',
              onPressed: () {
                for (var o in MockData.orderHistory) {
                  _changeOrderStatus(o, 'Pending');
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⏪ Đã tua về: Khôi phục tất cả đơn hàng về Chờ!'), backgroundColor: AppColors.info),
                );
              },
            ),
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
