import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/i_cart_repository.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/apply_coupon_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_quantity_usecase.dart';
import '../../../../core/providers/core_providers.dart';

// ---------------------------------------------------------------------------
// Repository Provider (singleton — aynı instance tüm app boyunca yaşar)
// ---------------------------------------------------------------------------
final cartRepositoryProvider = Provider<ICartRepository>((ref) {
  final dio = ref.watch(apiClientProvider).dio; // Dio inject
  return CartRepositoryImpl(dio: dio);
});

// ---------------------------------------------------------------------------
// CartNotifier — Riverpod 3.x Notifier pattern
// ---------------------------------------------------------------------------
class CartNotifier extends Notifier<CartEntity> {
  late final ICartRepository _repository;
  late final AddToCartUsecase _addToCart;
  late final RemoveFromCartUsecase _removeFromCart;
  late final UpdateCartQuantityUsecase _updateQuantity;
  late final ClearCartUsecase _clearCart;
  late final ApplyCouponUsecase _applyCoupon;

  static const _uuid = Uuid();

  @override
  CartEntity build() {
    _repository = ref.read(cartRepositoryProvider);
    _addToCart = AddToCartUsecase(_repository);
    _removeFromCart = RemoveFromCartUsecase(_repository);
    _updateQuantity = UpdateCartQuantityUsecase(_repository);
    _clearCart = ClearCartUsecase(_repository);
    _applyCoupon = ApplyCouponUsecase(_repository);

    // Hive'dan önceki sepeti yükle (async, state'i sonradan günceller)
    _loadCart();

    return const CartEntity();
  }

  Future<void> _loadCart() async {
    final result = await _repository.loadCart();
    result.fold(
      (_) {},
      (cart) => state = cart,
    );
  }

  /// Ürün ekle. Aynı productId+variantId varsa quantity artırılır.
  void addItem({
    required int productId,
    required String productName,
    String? productImageUrl,
    int? variantId,
    String? variantName,
    required double unitPrice,
    int quantity = 1,
    String? unit,
  }) {
    final item = CartItemEntity(
      id: _uuid.v4(),
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      variantId: variantId,
      variantName: variantName,
      unitPrice: unitPrice,
      quantity: quantity,
      unit: unit,
    );

    final result = _addToCart(item);
    result.fold(
      (_) {},
      (cart) {
        state = cart;
        _saveCart(cart);
      },
    );
  }

  /// Ürünü ID'ye göre sepetten çıkar.
  void removeItem(String itemId) {
    final result = _removeFromCart(itemId);
    result.fold(
      (_) {},
      (cart) {
        state = cart;
        _saveCart(cart);
      },
    );
  }

  /// Ürün miktarını güncelle. quantity=0 ise ürün kaldırılır.
  void updateQuantity(String itemId, int quantity) {
    final result = _updateQuantity(itemId, quantity);
    result.fold(
      (_) {},
      (cart) {
        state = cart;
        _saveCart(cart);
      },
    );
  }

  /// Sepeti tamamen temizle.
  void clearCart() {
    final result = _clearCart();
    result.fold(
      (_) {},
      (_) {
        state = const CartEntity();
        _saveCart(const CartEntity());
      },
    );
  }

  /// Kupon kodu uygula. Başarı durumunda true döner.
  Future<bool> applyCoupon(String couponCode) async {
    final result = await _applyCoupon(couponCode);
    return result.fold(
      (_) => false,
      (cart) {
        state = cart;
        _saveCart(cart);
        return true;
      },
    );
  }

  /// Uygulanmış kuponu kaldır.
  void removeCoupon() {
    final result = _repository.removeCoupon();
    result.fold(
      (_) {},
      (cart) {
        state = cart;
        _saveCart(cart);
      },
    );
  }

  /// Sipariş notunu güncelle.
  void updateNote(String note) {
    final result = _repository.updateNote(note);
    result.fold(
      (_) {},
      (cart) {
        state = cart;
        _saveCart(cart);
      },
    );
  }

  Future<void> _saveCart(CartEntity cart) async {
    await _repository.saveCart(cart);
  }

  /// Belirli bir ürünün sepetteki miktarını döner. Yoksa 0.
  int getItemQuantity(int productId, {int? variantId}) {
    final item = state.findItem(productId, variantId: variantId);
    return item?.quantity ?? 0;
  }

  /// Sepette bu ürün var mı?
  bool hasProduct(int productId, {int? variantId}) {
    return state.containsProduct(productId, variantId: variantId);
  }
}

// ---------------------------------------------------------------------------
// Ana cart provider
// ---------------------------------------------------------------------------
final cartNotifierProvider =
    NotifierProvider<CartNotifier, CartEntity>(CartNotifier.new);
