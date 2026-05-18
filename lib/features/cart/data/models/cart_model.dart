import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/variant_model.dart';

class CartItem extends Equatable {
  final ProductModel product;
  final VariantModel? variant;
  final int quantity;

  const CartItem({
    required this.product,
    this.variant,
    required this.quantity,
  });

  /// Toplam fiyat: varyant varsa varyant fiyatini kullan, yoksa product fallback
  double get total {
    final unitPrice = variant?.effectivePrice ?? product.effectivePrice;
    return unitPrice * quantity;
  }

  /// Birim fiyat
  double get unitPrice => variant?.effectivePrice ?? product.effectivePrice;

  CartItem copyWith({int? quantity, VariantModel? variant}) {
    return CartItem(
      product: product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  // Sepet ogesi kimligi: urun + varyant kombinasyonu
  List<Object?> get props => [product.id, variant?.id, quantity];
}

class CartModel extends Equatable {
  final List<CartItem> items;

  const CartModel({this.items = const []});

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.total);

  double get total => subtotal;

  bool get isEmpty => items.isEmpty;

  /// productId + variantId kombinasyonuyla arama
  bool containsProduct(String productId, {String? variantId}) {
    return items.any((item) =>
        item.product.id == productId && item.variant?.id == variantId);
  }

  /// productId + variantId kombinasyonunun miktari
  int quantityOf(String productId, {String? variantId}) {
    try {
      return items
          .firstWhere((item) =>
              item.product.id == productId && item.variant?.id == variantId)
          .quantity;
    } catch (_) {
      return 0;
    }
  }

  CartModel addItem(
    ProductModel product, {
    VariantModel? variant,
    int quantity = 1,
  }) {
    final existingIndex = items.indexWhere(
      (item) =>
          item.product.id == product.id && item.variant?.id == variant?.id,
    );

    final effectiveMaxQty = variant?.maxOrderQty ?? product.maxOrderQty;

    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(items);
      final existing = updatedItems[existingIndex];
      final newQty =
          (existing.quantity + quantity).clamp(0, effectiveMaxQty);
      updatedItems[existingIndex] = existing.copyWith(quantity: newQty);
      return CartModel(items: updatedItems);
    }

    return CartModel(
      items: [
        ...items,
        CartItem(product: product, variant: variant, quantity: quantity),
      ],
    );
  }

  /// productId + variantId kombinasyonunu kaldir
  CartModel removeItem(String productId, {String? variantId}) {
    return CartModel(
      items: items
          .where((item) => !(item.product.id == productId &&
              item.variant?.id == variantId))
          .toList(),
    );
  }

  /// Geriye donuk uyumluluk: sadece productId ile kaldir (variantsiz)
  CartModel removeItemById(String productId) {
    return CartModel(
      items: items.where((item) => item.product.id != productId).toList(),
    );
  }

  CartModel updateQuantity(
    String productId,
    int quantity, {
    String? variantId,
  }) {
    if (quantity <= 0) return removeItem(productId, variantId: variantId);
    final updatedItems = items.map((item) {
      if (item.product.id == productId && item.variant?.id == variantId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    return CartModel(items: updatedItems);
  }

  /// Sepetteki varyantları güncel VariantModel örnekleriyle değiştir.
  /// key: variantId, value: güncel VariantModel
  CartModel updateItemVariants(Map<String, VariantModel> variantUpdates) {
    final updated = items.map((item) {
      if (item.variant != null &&
          variantUpdates.containsKey(item.variant!.id)) {
        return item.copyWith(variant: variantUpdates[item.variant!.id]);
      }
      return item;
    }).toList();
    return CartModel(items: updated);
  }

  CartModel clear() => const CartModel();

  @override
  List<Object?> get props => [items];
}
