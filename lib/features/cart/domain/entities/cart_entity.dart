import 'package:equatable/equatable.dart';
import 'cart_item_entity.dart';

class CartEntity extends Equatable {
  final List<CartItemEntity> items;
  final String? couponCode;
  final double? discountAmount;
  final String? notes;

  const CartEntity({
    this.items = const [],
    this.couponCode,
    this.discountAmount,
    this.notes,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discount => discountAmount ?? 0.0;

  double get total => subtotal - discount;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  bool containsProduct(int productId, {int? variantId}) {
    return items.any((item) =>
        item.productId == productId && item.variantId == variantId);
  }

  CartItemEntity? findItem(int productId, {int? variantId}) {
    try {
      return items.firstWhere((item) =>
          item.productId == productId && item.variantId == variantId);
    } catch (_) {
      return null;
    }
  }

  CartEntity copyWith({
    List<CartItemEntity>? items,
    String? couponCode,
    double? discountAmount,
    String? notes,
  }) {
    return CartEntity(
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [items, couponCode, discountAmount];
}
