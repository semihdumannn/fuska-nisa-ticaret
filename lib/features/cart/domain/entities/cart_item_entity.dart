import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String id; // UUID - local identifier
  final int productId;
  final String productName;
  final String? productImageUrl;
  final int? variantId;
  final String? variantName;
  final double unitPrice;
  final int quantity;
  final String? unit; // 'adet', 'litre', 'kg'
  final Map<String, dynamic>? attributes;

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    this.variantId,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.unit,
    this.attributes,
  });

  double get totalPrice => unitPrice * quantity;

  String get displayName =>
      variantName != null ? '$productName - $variantName' : productName;

  CartItemEntity copyWith({
    String? id,
    int? productId,
    String? productName,
    String? productImageUrl,
    int? variantId,
    String? variantName,
    double? unitPrice,
    int? quantity,
    String? unit,
    Map<String, dynamic>? attributes,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  List<Object?> get props => [id, productId, variantId, quantity];
}
