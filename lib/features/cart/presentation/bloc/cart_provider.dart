import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/variant_model.dart';
import '../../data/models/cart_model.dart';

class CartNotifier extends Notifier<CartModel> {
  @override
  CartModel build() => const CartModel();

  /// Sepete urun ekle. Varyant secilmisse variant'i da gecir.
  void addItem(
    ProductModel product, {
    VariantModel? variant,
    int quantity = 1,
  }) {
    state = state.addItem(product, variant: variant, quantity: quantity);
  }

  /// productId + variantId kombinasyonunu kaldir.
  void removeItem(String productId, {String? variantId}) {
    state = state.removeItem(productId, variantId: variantId);
  }

  /// productId + variantId kombinasyonunun miktarini guncelle.
  void updateQuantity(
    String productId,
    int quantity, {
    String? variantId,
  }) {
    state = state.updateQuantity(productId, quantity, variantId: variantId);
  }

  /// productId + variantId kombinasyonunu bir azalt; 1'deyse kaldir.
  void decreaseItem(String productId, {String? variantId}) {
    final currentQty = state.quantityOf(productId, variantId: variantId);
    if (currentQty <= 1) {
      state = state.removeItem(productId, variantId: variantId);
    } else {
      state = state.updateQuantity(
        productId,
        currentQty - 1,
        variantId: variantId,
      );
    }
  }

  void clear() {
    state = state.clear();
  }

  /// Sepetteki variant fiyatlarını günceller (checkout doğrulamasından sonra).
  void updateVariants(Map<String, VariantModel> variantUpdates) {
    state = state.updateItemVariants(variantUpdates);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartModel>(
  CartNotifier.new,
);
