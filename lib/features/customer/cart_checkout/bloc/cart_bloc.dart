import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/mock_data.dart';

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

  const CartState({
    this.items = const [],
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.appliedCoupon,
    this.errorMessage,
    this.isCouponValid = false,
  });

  CartState copyWith({
    List<MockCartItem>? items,
    double? subtotal,
    double? discount,
    double? total,
    MockCoupon? appliedCoupon,
    String? errorMessage,
    bool? isCouponValid,
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      errorMessage: errorMessage, // Reset if null
      isCouponValid: isCouponValid ?? this.isCouponValid,
    );
  }

  @override
  List<Object?> get props => [items, subtotal, discount, total, appliedCoupon, errorMessage, isCouponValid];
}

// --- BLOC ---
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ApplyDiscountCoupon>(_onApplyDiscountCoupon);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final updatedItems = List<MockCartItem>.from(state.items);
    
    // Check if item with same product, size, sugar, ice, toppings already exists
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

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  // --- HELPERS ---
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
        // Invalidate coupon if subtotal fell below minOrder
        finalCoupon = null;
      }
    }

    double total = (subtotal - discount).clamp(0, double.infinity);

    emit(CartState(
      items: items,
      subtotal: subtotal,
      discount: discount,
      total: total,
      appliedCoupon: finalCoupon,
      isCouponValid: finalCoupon != null,
    ));
  }
}
