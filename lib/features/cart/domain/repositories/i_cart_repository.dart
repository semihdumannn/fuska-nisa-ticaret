import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart_entity.dart';
import '../entities/cart_item_entity.dart';

abstract class ICartRepository {
  /// Mevcut sepeti döner
  CartEntity getCart();

  /// Sepete ürün ekler. Zaten varsa quantity'yi artırır.
  Either<Failure, CartEntity> addItem(CartItemEntity item);

  /// Ürünü sepetten çıkarır
  Either<Failure, CartEntity> removeItem(String itemId);

  /// Ürün miktarını günceller. quantity=0 ise siler.
  Either<Failure, CartEntity> updateQuantity(String itemId, int quantity);

  /// Sepeti temizler
  Either<Failure, void> clearCart();

  /// Kuponu uygula
  Future<Either<Failure, CartEntity>> applyCoupon(String couponCode);

  /// Kuponu kaldır
  Either<Failure, CartEntity> removeCoupon();

  /// Notu güncelle
  Either<Failure, CartEntity> updateNote(String note);

  /// Sepeti yerel depolamaya kaydet
  Future<Either<Failure, void>> saveCart(CartEntity cart);

  /// Yerel depolamadan sepeti yükle
  Future<Either<Failure, CartEntity>> loadCart();
}
