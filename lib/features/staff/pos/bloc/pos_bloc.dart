import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/network/api_service.dart';

// --- EVENTS ---
abstract class POSEvent extends Equatable {
  const POSEvent();
  @override
  List<Object?> get props => [];
}

class POSAddItem extends POSEvent {
  final MockProduct product;
  const POSAddItem(this.product);

  @override
  List<Object?> get props => [product];
}

class POSUpdateQuantity extends POSEvent {
  final String itemId;
  final int quantity;
  const POSUpdateQuantity(this.itemId, this.quantity);

  @override
  List<Object?> get props => [itemId, quantity];
}

class POSRemoveItem extends POSEvent {
  final String itemId;
  const POSRemoveItem(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class POSCheckoutRequested extends POSEvent {
  final String paymentMethod; // CASH, QR
  final double amountReceived; // only for CASH
  final String? token;
  final int branchId;

  const POSCheckoutRequested({
    required this.paymentMethod,
    this.amountReceived = 0,
    this.token,
    this.branchId = 1,
  });

  @override
  List<Object?> get props => [paymentMethod, amountReceived, token, branchId];
}

class POSClearOrder extends POSEvent {}

// --- STATES ---
class POSState extends Equatable {
  final List<MockCartItem> orderItems;
  final double totalAmount;
  final String? errorMessage;
  final bool isSuccess;
  final double changeReturned; // Tiền thừa thối khách
  final String? lastOrderCode;

  const POSState({
    this.orderItems = const [],
    this.totalAmount = 0,
    this.errorMessage,
    this.isSuccess = false,
    this.changeReturned = 0,
    this.lastOrderCode,
  });

  POSState copyWith({
    List<MockCartItem>? orderItems,
    double? totalAmount,
    String? errorMessage,
    bool? isSuccess,
    double? changeReturned,
    String? lastOrderCode,
  }) {
    return POSState(
      orderItems: orderItems ?? this.orderItems,
      totalAmount: totalAmount ?? this.totalAmount,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      changeReturned: changeReturned ?? this.changeReturned,
      lastOrderCode: lastOrderCode ?? this.lastOrderCode,
    );
  }

  @override
  List<Object?> get props => [orderItems, totalAmount, errorMessage, isSuccess, changeReturned, lastOrderCode];
}

// --- BLOC ---
class POSBloc extends Bloc<POSEvent, POSState> {
  POSBloc() : super(const POSState()) {
    on<POSAddItem>(_onAddItem);
    on<POSUpdateQuantity>(_onUpdateQuantity);
    on<POSRemoveItem>(_onRemoveItem);
    on<POSCheckoutRequested>(_onCheckoutRequested);
    on<POSClearOrder>(_onClearOrder);
  }

  void _onAddItem(POSAddItem event, Emitter<POSState> emit) {
    final updatedItems = List<MockCartItem>.from(state.orderItems);
    
    // Check if item already exists in cashier cart (default Size M, no toppings, normal sugar/ice)
    final existingIndex = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (existingIndex >= 0) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = MockCartItem(
        id: existing.id,
        product: existing.product,
        size: 'M',
        selectedToppings: const [],
        quantity: existing.quantity + 1,
      );
    } else {
      updatedItems.add(MockCartItem(
        id: 'pos_ci_${DateTime.now().millisecondsSinceEpoch}',
        product: event.product,
        size: 'M',
        selectedToppings: const [],
        quantity: 1,
      ));
    }

    _calculateTotals(updatedItems, emit);
  }

  void _onUpdateQuantity(POSUpdateQuantity event, Emitter<POSState> emit) {
    if (event.quantity <= 0) {
      add(POSRemoveItem(event.itemId));
      return;
    }

    final updatedItems = state.orderItems.map((item) {
      if (item.id == event.itemId) {
        return MockCartItem(
          id: item.id,
          product: item.product,
          size: item.size,
          selectedToppings: item.selectedToppings,
          quantity: event.quantity,
        );
      }
      return item;
    }).toList();

    _calculateTotals(updatedItems, emit);
  }

  void _onRemoveItem(POSRemoveItem event, Emitter<POSState> emit) {
    final updatedItems = state.orderItems.where((item) => item.id != event.itemId).toList();
    _calculateTotals(updatedItems, emit);
  }

  Future<void> _onCheckoutRequested(POSCheckoutRequested event, Emitter<POSState> emit) async {
    if (state.orderItems.isEmpty) {
      emit(state.copyWith(errorMessage: 'Đơn hàng trống!'));
      return;
    }

    double change = 0;
    if (event.paymentMethod == 'CASH') {
      if (event.amountReceived < state.totalAmount) {
        emit(state.copyWith(errorMessage: 'Số tiền khách đưa không đủ!'));
        return;
      }
      change = event.amountReceived - state.totalAmount;
    }

    String orderCode = 'POS-${1000 + DateTime.now().second * 17}';

    if (event.token != null) {
      try {
        final res = await ApiService.instance.placePOSOrder(
          branchId: event.branchId,
          items: state.orderItems,
          paymentMethod: event.paymentMethod,
          token: event.token!,
        );
        orderCode = res['orderCode'] ?? orderCode;
      } catch (e) {
        print('POS API place order error, fallback local: $e');
      }
    }

    // Mock create and add POS order to global history
    final newOrder = MockOrder(
      id: 'ord_pos_${DateTime.now().millisecondsSinceEpoch}',
      orderCode: orderCode,
      branchName: MockData.branches[0].name,
      items: List.from(state.orderItems),
      totalAmount: state.totalAmount,
      discountAmount: 0,
      finalAmount: state.totalAmount,
      paymentMethod: event.paymentMethod,
      status: 'CONFIRMED', // POS orders are immediately confirmed
      createdAt: DateTime.now(),
      source: 'POS',
    );
    MockData.orderHistory.insert(0, newOrder);

    emit(POSState(
      orderItems: const [],
      totalAmount: 0,
      isSuccess: true,
      changeReturned: change,
      lastOrderCode: orderCode,
    ));
  }

  void _onClearOrder(POSClearOrder event, Emitter<POSState> emit) {
    emit(const POSState());
  }

  void _calculateTotals(List<MockCartItem> items, Emitter<POSState> emit) {
    double total = 0;
    for (var item in items) {
      total += item.totalPrice;
    }
    emit(state.copyWith(
      orderItems: items,
      totalAmount: total,
      isSuccess: false,
    ));
  }
}
