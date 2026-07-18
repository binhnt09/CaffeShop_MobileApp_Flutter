import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/network/api_service.dart';

// --- EVENTS ---
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final MockCartItem item;
  const AddToCart(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateCartItemQuantity extends CartEvent {
  final String itemId;
  final int quantity;
  const UpdateCartItemQuantity(this.itemId, this.quantity);

  @override
  List<Object?> get props => [itemId, quantity];
}

class RemoveFromCart extends CartEvent {
  final String itemId;
  const RemoveFromCart(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ApplyDiscountCoupon extends CartEvent {
  final String code;
  const ApplyDiscountCoupon(this.code);

  @override
  List<Object?> get props => [code];
}

class ValidateCouponFromAPI extends CartEvent {
  final String code;
  const ValidateCouponFromAPI(this.code);

  @override
  List<Object?> get props => [code];
}

class RemoveCoupon extends CartEvent {}

class PlaceOrderEvent extends CartEvent {
  final int branchId;
  final String fulfillmentMode;
  final String paymentMethod;
  final String token;
  final int redeemPoints;

  const PlaceOrderEvent({
    required this.branchId,
    required this.fulfillmentMode,
    required this.paymentMethod,
    required this.token,
    this.redeemPoints = 0,
  });

  @override
  List<Object?> get props => [branchId, fulfillmentMode, paymentMethod, token, redeemPoints];
}

class ClearCart extends CartEvent {}

// --- STATES ---
class CartState extends Equatable {
  final List<MockCartItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final MockCoupon? appliedCoupon;
  final String? errorMessage;
  final bool isCouponValid;
  final bool isLoading;
  final bool isOrderSuccess;
  final PlaceOrderResponse? orderResponse;

  const CartState({
    this.items = const [],
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.appliedCoupon,
    this.errorMessage,
    this.isCouponValid = false,
    this.isLoading = false,
    this.isOrderSuccess = false,
    this.orderResponse,
  });

  CartState copyWith({
    List<MockCartItem>? items,
    double? subtotal,
    double? discount,
    double? total,
    MockCoupon? appliedCoupon,
    String? errorMessage,
    bool? isCouponValid,
    bool? isLoading,
    bool? isOrderSuccess,
    PlaceOrderResponse? orderResponse,
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      errorMessage: errorMessage, // Reset if null
      isCouponValid: isCouponValid ?? this.isCouponValid,
      isLoading: isLoading ?? this.isLoading,
      isOrderSuccess: isOrderSuccess ?? this.isOrderSuccess,
      orderResponse: orderResponse ?? this.orderResponse,
    );
  }

  @override
  List<Object?> get props => [
        items,
        subtotal,
        discount,
        total,
        appliedCoupon,
        errorMessage,
        isCouponValid,
        isLoading,
        isOrderSuccess,
        orderResponse
      ];
}

// --- BLOC ---
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ApplyDiscountCoupon>(_onApplyDiscountCoupon);
    on<ValidateCouponFromAPI>(_onValidateCouponFromAPI);
    on<RemoveCoupon>(_onRemoveCoupon);
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final updatedItems = List<MockCartItem>.from(state.items);
    
    int existingIndex = -1;
    for (int i = 0; i < updatedItems.length; i++) {
      final existing = updatedItems[i];
      if (existing.product.id == event.item.product.id &&
          existing.size == event.item.size &&
          existing.sugarLevel == event.item.sugarLevel &&
          existing.iceLevel == event.item.iceLevel &&
          _areToppingsEqual(existing.selectedToppings, event.item.selectedToppings)) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex >= 0) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = MockCartItem(
        id: existing.id,
        product: existing.product,
        size: existing.size,
        sugarLevel: existing.sugarLevel,
        iceLevel: existing.iceLevel,
        selectedToppings: existing.selectedToppings,
        quantity: existing.quantity + event.item.quantity,
      );
    } else {
      updatedItems.add(event.item);
    }

    _calculateTotals(updatedItems, state.appliedCoupon, emit);
  }

  void _onUpdateCartItemQuantity(UpdateCartItemQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(RemoveFromCart(event.itemId));
      return;
    }
    
    final updatedItems = state.items.map((item) {
      if (item.id == event.itemId) {
        return MockCartItem(
          id: item.id,
          product: item.product,
          size: item.size,
          sugarLevel: item.sugarLevel,
          iceLevel: item.iceLevel,
          selectedToppings: item.selectedToppings,
          quantity: event.quantity,
        );
      }
      return item;
    }).toList();

    _calculateTotals(updatedItems, state.appliedCoupon, emit);
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final updatedItems = state.items.where((item) => item.id != event.itemId).toList();
    _calculateTotals(updatedItems, state.appliedCoupon, emit);
  }

  void _onApplyDiscountCoupon(ApplyDiscountCoupon event, Emitter<CartState> emit) {
    if (event.code.isEmpty) {
      emit(state.copyWith(errorMessage: 'Mã giảm giá trống.'));
      return;
    }

    try {
      final coupon = MockData.coupons.firstWhere(
        (c) => c.code.toUpperCase() == event.code.toUpperCase(),
      );

      if (state.subtotal < coupon.minOrder) {
        emit(state.copyWith(
          errorMessage: 'Đơn hàng chưa đạt giá trị tối thiểu ${coupon.minOrder.toInt()}đ để áp dụng mã này.',
          isCouponValid: false,
        ));
        return;
      }

      _calculateTotals(state.items, coupon, emit);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Mã giảm giá không tồn tại hoặc đã hết hạn.',
        isCouponValid: false,
      ));
    }
  }

  Future<void> _onValidateCouponFromAPI(
      ValidateCouponFromAPI event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await ApiService.instance.validateCoupon(event.code, state.subtotal);
      if (result.valid) {
        final fakeCoupon = MockCoupon(
          code: result.couponCode,
          description: result.message,
          discountType: 'FIXED',
          discountValue: result.discountAmount,
          minOrder: 0,
        );
        _calculateTotals(state.items, fakeCoupon, emit);
      } else {
        emit(state.copyWith(errorMessage: result.message, isCouponValid: false, isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Lỗi kiểm tra mã giảm giá', isCouponValid: false, isLoading: false));
    }
  }

  void _onRemoveCoupon(RemoveCoupon event, Emitter<CartState> emit) {
    _calculateTotals(state.items, null, emit);
  }

  Future<void> _onPlaceOrder(PlaceOrderEvent event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, isOrderSuccess: false));
    try {
      final orderItems = state.items.map((item) => OrderItemRequest(
        menuItemId: int.parse(item.product.id),
        quantity: item.quantity,
        customizationOptionIds: item.selectedToppings.map((t) => int.parse(t.id)).toList(),
        notes: "Size: ${item.size}, Sugar: ${item.sugarLevel}%, Ice: ${item.iceLevel}%",
      )).toList();

      final request = PlaceOrderRequest(
        branchId: event.branchId,
        fulfillmentMode: event.fulfillmentMode,
        paymentMethod: event.paymentMethod,
        couponCode: state.appliedCoupon?.code,
        redeemPoints: event.redeemPoints > 0 ? event.redeemPoints : null,
        items: orderItems,
      );

      final response = await ApiService.instance.placeOrder(request, event.token);
      if (response != null) {
        emit(state.copyWith(
          isLoading: false,
          isOrderSuccess: true,
          orderResponse: response,
          items: const [],
          subtotal: 0,
          discount: 0,
          total: 0,
          appliedCoupon: null,
          isCouponValid: false,
        ));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Đặt hàng không thành công'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Lỗi: ${e.toString()}'));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  bool _areToppingsEqual(List<MockTopping> a, List<MockTopping> b) {
    if (a.length != b.length) return false;
    final idsA = a.map((t) => t.id).toList()..sort();
    final idsB = b.map((t) => t.id).toList()..sort();
    for (int i = 0; i < idsA.length; i++) {
      if (idsA[i] != idsB[i]) return false;
    }
    return true;
  }

  void _calculateTotals(List<MockCartItem> items, MockCoupon? coupon, Emitter<CartState> emit) {
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.totalPrice;
    }

    double discount = 0;
    MockCoupon? finalCoupon = coupon;

    if (coupon != null) {
      if (subtotal >= coupon.minOrder) {
        if (coupon.discountType == 'PERCENT') {
          discount = subtotal * (coupon.discountValue / 100);
        } else {
          discount = coupon.discountValue;
        }
      } else {
        finalCoupon = null;
      }
    }

    double total = (subtotal - discount).clamp(0, double.infinity);

    emit(state.copyWith(
      items: items,
      subtotal: subtotal,
      discount: discount,
      total: total,
      appliedCoupon: finalCoupon,
      isCouponValid: finalCoupon != null,
      isLoading: false,
    ));
  }
}
