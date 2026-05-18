import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ─── Factory constructors ──────────────────────────────────────────────────

  factory VariantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VariantModel(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      sku: data['sku'] as String?,
      barcode: data['barcode'] as String?,
      price: (data['price'] as num? ?? 0).toDouble(),
      salePrice: (data['salePrice'] as num?)?.toDouble(),
      unit: data['unit'] as String? ?? 'adet',
      stock: (data['stock'] as num? ?? 0).toInt(),
      minOrderQty: (data['minOrderQty'] as num? ?? 1).toInt(),
      maxOrderQty: (data['maxOrderQty'] as num? ?? 999).toInt(),
      packageQty: (data['packageQty'] as num?)?.toInt(),
      palletPackageQty: (data['palletPackageQty'] as num?)?.toInt(),
      palletWeight: (data['palletWeight'] as num?)?.toDouble(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: (json['price'] as num? ?? 0).toDouble(),
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'adet',
      stock: (json['stock'] as num? ?? 0).toInt(),
      minOrderQty: (json['minOrderQty'] as num? ?? 1).toInt(),
      maxOrderQty: (json['maxOrderQty'] as num? ?? 999).toInt(),
      packageQty: (json['packageQty'] as num?)?.toInt(),
      palletPackageQty: (json['palletPackageQty'] as num?)?.toInt(),
      palletWeight: (json['palletWeight'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'salePrice': salePrice,
      'unit': unit,
      'stock': stock,
      'minOrderQty': minOrderQty,
      'maxOrderQty': maxOrderQty,
      'packageQty': packageQty,
      'palletPackageQty': palletPackageQty,
      'palletWeight': palletWeight,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'salePrice': salePrice,
      'unit': unit,
      'stock': stock,
      'minOrderQty': minOrderQty,
      'maxOrderQty': maxOrderQty,
      'packageQty': packageQty,
      'palletPackageQty': palletPackageQty,
      'palletWeight': palletWeight,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

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
