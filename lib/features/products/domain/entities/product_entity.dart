import 'package:equatable/equatable.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/models/variant_model.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<String> categoryIds;
  final String brandId;
  final bool isActive;
  final bool isFeatured;

  // Denormalize fiyat alanları (ProductModel'e paralel)
  final double? primaryPrice;
  final double? primarySalePrice;
  final int? primaryStock;

  // Koli varyant snapshot
  final String? koliVariantId;
  final double? koliPrice;
  final double? koliSalePrice;
  final int? koliStock;
  final int? koliPackageQty;

  final List<ProductVariantEntity> variants;
  final List<String> tags;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl,
    this.imageUrls = const [],
    this.categoryIds = const [],
    this.brandId = '',
    this.isActive = true,
    this.isFeatured = false,
    this.primaryPrice,
    this.primarySalePrice,
    this.primaryStock,
    this.koliVariantId,
    this.koliPrice,
    this.koliSalePrice,
    this.koliStock,
    this.koliPackageQty,
    this.variants = const [],
    this.tags = const [],
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Geriye dönük uyumluluk
  String get categoryId => categoryIds.isNotEmpty ? categoryIds.first : '';

  double get price => koliPrice ?? primaryPrice ?? 0.0;

  double get effectivePrice =>
      koliSalePrice ?? koliPrice ?? primarySalePrice ?? primaryPrice ?? 0.0;

  bool get hasDiscount {
    final p = koliPrice ?? primaryPrice;
    final s = koliSalePrice ?? primarySalePrice;
    return p != null && p > 0 && s != null && s < p;
  }

  double get discountPercentage {
    final p = koliPrice ?? primaryPrice;
    final s = koliSalePrice ?? primarySalePrice;
    if (p == null || p <= 0 || s == null || s >= p) return 0.0;
    return ((p - s) / p * 100).roundToDouble();
  }

  bool get inStock {
    if (koliVariantId != null) return (koliStock ?? 0) > 0;
    return (primaryStock ?? 0) > 0;
  }

  int get stock => koliStock ?? primaryStock ?? 0;

  List<String> get allImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  ProductModel toProductModel() {
    return ProductModel(
      id: id,
      brandId: brandId,
      name: name,
      description: description,
      categoryIds: categoryIds,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      tags: tags,
      isActive: isActive,
      isFeatured: isFeatured,
      order: order,
      createdAt: createdAt,
      updatedAt: updatedAt,
      primaryPrice: primaryPrice,
      primarySalePrice: primarySalePrice,
      primaryStock: primaryStock,
      koliVariantId: koliVariantId,
      koliPrice: koliPrice,
      koliSalePrice: koliSalePrice,
      koliStock: koliStock,
      koliPackageQty: koliPackageQty,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        categoryIds,
        brandId,
        isActive,
        koliPrice ?? primaryPrice,
      ];
}

class ProductVariantEntity extends Equatable {
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
  final bool isActive;

  const ProductVariantEntity({
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
    this.isActive = true,
  });

  double get effectivePrice => salePrice ?? price;

  bool get hasDiscount => salePrice != null && salePrice! < price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((price - salePrice!) / price * 100).roundToDouble();
  }

  bool get inStock => stock > 0;

  VariantModel toVariantModel() {
    final now = DateTime.now();
    return VariantModel(
      id: id,
      productId: productId,
      name: name,
      sku: sku,
      barcode: barcode,
      price: price,
      salePrice: salePrice,
      unit: unit,
      stock: stock,
      minOrderQty: minOrderQty,
      maxOrderQty: maxOrderQty,
      packageQty: packageQty,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [id, productId, name, price, salePrice, stock, isActive];
}
