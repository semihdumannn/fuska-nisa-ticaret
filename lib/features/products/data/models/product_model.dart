import 'package:equatable/equatable.dart';

import 'variant_model.dart';

class ProductModel extends Equatable {
  final String id;
  final String brandId;
  final String name;
  final String description;
  final List<String> categoryIds;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalize adet fiyatı (ProductCard fallback için)
  final double? primaryPrice;
  final double? primarySalePrice;
  final int? primaryStock;

  // Denormalize koli snapshot (N+1 olmadan direkt sepete eklemek için)
  final String? koliVariantId;
  final double? koliPrice;
  final double? koliSalePrice;
  final int? koliStock;
  final int? koliPackageQty;

  const ProductModel({
    required this.id,
    this.brandId = '',
    required this.name,
    required this.description,
    this.categoryIds = const [],
    this.imageUrl,
    this.imageUrls = const [],
    this.tags = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.primaryPrice,
    this.primarySalePrice,
    this.primaryStock,
    this.koliVariantId,
    this.koliPrice,
    this.koliSalePrice,
    this.koliStock,
    this.koliPackageQty,
  });

  // ─── Geriye dönük uyumluluk ──────────────────────────────────────────────

  /// Geriye dönük uyumluluk — categoryId'yi hala kullanan yerler için
  String get categoryId => categoryIds.isNotEmpty ? categoryIds.first : '';

  // ─── Fiyat / stok getterları ─────────────────────────────────────────────

  double get price => koliPrice ?? primaryPrice ?? 0.0;

  double get effectivePrice =>
      koliSalePrice ?? koliPrice ?? primarySalePrice ?? primaryPrice ?? 0.0;

  bool get hasDiscount {
    final p = koliPrice ?? primaryPrice;
    final s = koliSalePrice ?? primarySalePrice;
    return p != null && p > 0 && s != null && s < p;
  }

  double get discountPercent {
    final p = koliPrice ?? primaryPrice;
    final s = koliSalePrice ?? primarySalePrice;
    if (p == null || p <= 0 || s == null || s >= p) return 0.0;
    return ((p - s) / p * 100).roundToDouble();
  }

  bool get inStock {
    if (koliVariantId != null && koliStock != null) return koliStock! > 0;
    return (primaryStock ?? 0) > 0;
  }

  String get unit => 'koli';

  int get stock => koliStock ?? primaryStock ?? 0;

  int get minOrderQty => 1;

  int get maxOrderQty => 999;

  // ─── Koli varyant nesnesi (sepete ekleme için) ────────────────────────────

  VariantModel? get koliVariant {
    if (koliVariantId == null) return null;
    return VariantModel(
      id: koliVariantId!,
      productId: id,
      name: '$name - Koli',
      price: koliPrice ?? 0,
      salePrice: koliSalePrice,
      unit: 'koli',
      stock: koliStock ?? 0,
      packageQty: koliPackageQty,
      minOrderQty: 1,
      maxOrderQty: 999,
      isActive: true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Gorsel yardimcisi ───────────────────────────────────────────────────

  List<String> get allImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  ProductModel copyWith({
    String? id,
    String? brandId,
    String? name,
    String? description,
    List<String>? categoryIds,
    String? imageUrl,
    bool clearImageUrl = false,
    List<String>? imageUrls,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? primaryPrice,
    double? primarySalePrice,
    bool clearPrimaryPrice = false,
    int? primaryStock,
    bool clearPrimaryStock = false,
    String? koliVariantId,
    double? koliPrice,
    double? koliSalePrice,
    int? koliStock,
    int? koliPackageQty,
    bool clearKoli = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryIds: categoryIds ?? this.categoryIds,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      primaryPrice:
          clearPrimaryPrice ? null : (primaryPrice ?? this.primaryPrice),
      primarySalePrice:
          clearPrimaryPrice ? null : (primarySalePrice ?? this.primarySalePrice),
      primaryStock:
          clearPrimaryStock ? null : (primaryStock ?? this.primaryStock),
      koliVariantId: clearKoli ? null : (koliVariantId ?? this.koliVariantId),
      koliPrice: clearKoli ? null : (koliPrice ?? this.koliPrice),
      koliSalePrice: clearKoli ? null : (koliSalePrice ?? this.koliSalePrice),
      koliStock: clearKoli ? null : (koliStock ?? this.koliStock),
      koliPackageQty: clearKoli ? null : (koliPackageQty ?? this.koliPackageQty),
    );
  }

  @override
  List<Object?> get props => [
        id,
        brandId,
        name,
        categoryIds,
        isActive,
        imageUrls,
        koliPrice ?? primaryPrice,
      ];
}
