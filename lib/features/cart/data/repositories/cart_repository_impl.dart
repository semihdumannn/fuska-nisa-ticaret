import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/i_cart_repository.dart';

class CartRepositoryImpl implements ICartRepository {
  static const String _cartBoxName = 'cart_data';
  static const String _cartKey = 'current_cart';

  final Dio? _dio; // nullable - coupon için opsiyonel

  CartRepositoryImpl({Dio? dio}) : _dio = dio;

  Box<dynamic>? _cartBox;

  Future<Box<dynamic>> get _box async {
    if (_cartBox != null && _cartBox!.isOpen) return _cartBox!;
    _cartBox = await Hive.openBox(_cartBoxName);
    return _cartBox!;
  }

  // In-memory cart (primary state)
  CartEntity _cart = const CartEntity();

  @override
  CartEntity getCart() => _cart;

  @override
  Either<Failure, CartEntity> addItem(CartItemEntity item) {
    try {
      final existingIndex = _cart.items.indexWhere(
        (i) => i.productId == item.productId && i.variantId == item.variantId,
      );

      List<CartItemEntity> newItems;
      if (existingIndex >= 0) {
        // Mevcut ürünün miktarını artır
        newItems = List.from(_cart.items);
        final existing = newItems[existingIndex];
        newItems[existingIndex] =
            existing.copyWith(quantity: existing.quantity + item.quantity);
      } else {
        // Yeni ürün ekle
        newItems = [..._cart.items, item];
      }

      _cart = _cart.copyWith(items: newItems);
      return Right(_cart);
    } catch (e) {
      return Left(ServerFailure('Ürün sepete eklenemedi: $e'));
    }
  }

  @override
  Either<Failure, CartEntity> removeItem(String itemId) {
    try {
      final newItems = _cart.items.where((i) => i.id != itemId).toList();
      _cart = _cart.copyWith(items: newItems);
      return Right(_cart);
    } catch (e) {
      return Left(ServerFailure('Ürün sepetten çıkarılamadı: $e'));
    }
  }

  @override
  Either<Failure, CartEntity> updateQuantity(String itemId, int quantity) {
    try {
      if (quantity == 0) {
        return removeItem(itemId);
      }

      final newItems = _cart.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();

      _cart = _cart.copyWith(items: newItems);
      return Right(_cart);
    } catch (e) {
      return Left(ServerFailure('Miktar güncellenemedi: $e'));
    }
  }

  @override
  Either<Failure, void> clearCart() {
    try {
      _cart = const CartEntity();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Sepet temizlenemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> applyCoupon(String couponCode) async {
    try {
      if (_dio != null) {
        final response = await _dio!.post(
          ApiEndpoints.validateCoupon,
          data: {
            'code': couponCode,
            'cart_total': _cart.subtotal,
          },
        );

        final data = response.data['data'] as Map<String, dynamic>;
        final discountAmount =
            (data['discount_amount'] as num?)?.toDouble() ?? 0;
        final discountType =
            data['discount_type'] as String? ?? 'fixed';

        double finalDiscount;
        if (discountType == 'percentage') {
          finalDiscount = _cart.subtotal * (discountAmount / 100);
        } else {
          finalDiscount = discountAmount;
        }

        _cart = _cart.copyWith(
          couponCode: couponCode,
          discountAmount: finalDiscount,
        );
      } else {
        // Fallback: kupon kodu kaydet, indirim 0
        _cart = _cart.copyWith(couponCode: couponCode, discountAmount: 0);
      }

      await _saveCartToHive(_cart);
      return Right(_cart);
    } on DioException catch (e) {
      return Left(ExceptionHandler.handleException(e));
    } catch (e) {
      return Left(ServerFailure('Kupon uygulanamadı: $e'));
    }
  }

  @override
  Either<Failure, CartEntity> removeCoupon() {
    try {
      _cart = CartEntity(
        items: _cart.items,
        notes: _cart.notes,
      );
      return Right(_cart);
    } catch (e) {
      return Left(ServerFailure('Kupon kaldırılamadı: $e'));
    }
  }

  @override
  Either<Failure, CartEntity> updateNote(String note) {
    try {
      _cart = _cart.copyWith(notes: note.isEmpty ? null : note);
      return Right(_cart);
    } catch (e) {
      return Left(ServerFailure('Not güncellenemedi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveCart(CartEntity cart) async {
    try {
      await _saveCartToHive(cart);
      _cart = cart;
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Sepet kaydedilemedi: $e'));
    }
  }

  /// Sepeti Hive'a yazar. applyCoupon ve saveCart tarafından ortak kullanılır.
  Future<void> _saveCartToHive(CartEntity cart) async {
    final box = await _box;
    final cartData = {
      'items': cart.items
          .map((item) => {
                'id': item.id,
                'product_id': item.productId,
                'product_name': item.productName,
                'product_image_url': item.productImageUrl,
                'variant_id': item.variantId,
                'variant_name': item.variantName,
                'unit_price': item.unitPrice,
                'quantity': item.quantity,
                'unit': item.unit,
              })
          .toList(),
      'coupon_code': cart.couponCode,
      'discount_amount': cart.discountAmount,
      'notes': cart.notes,
    };
    await box.put(_cartKey, cartData);
  }

  @override
  Future<Either<Failure, CartEntity>> loadCart() async {
    try {
      final box = await _box;
      final cartData = box.get(_cartKey);

      if (cartData == null) {
        return Right(const CartEntity());
      }

      final itemsRaw = cartData['items'] as List? ?? [];
      final items = itemsRaw.map((itemMap) {
        final map = itemMap as Map;
        return CartItemEntity(
          id: map['id'] as String,
          productId: map['product_id'] as int,
          productName: map['product_name'] as String,
          productImageUrl: map['product_image_url'] as String?,
          variantId: map['variant_id'] as int?,
          variantName: map['variant_name'] as String?,
          unitPrice: (map['unit_price'] as num).toDouble(),
          quantity: map['quantity'] as int,
          unit: map['unit'] as String?,
        );
      }).toList();

      _cart = CartEntity(
        items: items,
        couponCode: cartData['coupon_code'] as String?,
        discountAmount: (cartData['discount_amount'] as num?)?.toDouble(),
        notes: cartData['notes'] as String?,
      );

      return Right(_cart);
    } catch (e) {
      return Right(const CartEntity()); // Hata durumunda boş sepet
    }
  }
}
