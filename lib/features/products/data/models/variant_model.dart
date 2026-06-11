import 'package:equatable/equatable.dart';

class VariantModel extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double? salePrice;
  final String unit;
  final int stock;
  final int minOrderQty;
  final int maxOrderQty;
  final int? packageQty;
  final int? palletPackageQty;
  final double? palletWeight;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VariantModel({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.salePrice,
    required this.unit,
    required this.stock,
    this.minOrderQty = 1,
    this.maxOrderQty = 999,
    this.packageQty,
    this.palletPackageQty,
    this.palletWeight,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── Computed getters ───────────────────────────────────────────────────────

  /// Gecerli satis fiyati: indirim varsa salePrice, yoksa price
  double get effectivePrice => salePrice ?? price;

  bool get hasDiscount => salePrice != null && salePrice! < price;

  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((price - salePrice!) / price * 100).roundToDouble();
  }

  bool get inStock => stock > 0;

  VariantModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? sku,
    bool clearSku = false,
    String? barcode,
    bool clearBarcode = false,
    double? price,
    double? salePrice,
    bool clearSalePrice = false,
    String? unit,
    int? stock,
    int? minOrderQty,
    int? maxOrderQty,
    int? packageQty,
    bool clearPackageQty = false,
    int? palletPackageQty,
    bool clearPalletPackageQty = false,
    double? palletWeight,
    bool clearPalletWeight = false,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VariantModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      sku: clearSku ? null : (sku ?? this.sku),
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      price: price ?? this.price,
      salePrice: clearSalePrice ? null : (salePrice ?? this.salePrice),
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      maxOrderQty: maxOrderQty ?? this.maxOrderQty,
      packageQty: clearPackageQty ? null : (packageQty ?? this.packageQty),
      palletPackageQty: clearPalletPackageQty
          ? null
          : (palletPackageQty ?? this.palletPackageQty),
      palletWeight:
          clearPalletWeight ? null : (palletWeight ?? this.palletWeight),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, productId, name, price, salePrice, stock, isActive];
}
