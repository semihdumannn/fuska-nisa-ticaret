import '../../domain/entities/product_entity.dart';

class ApiProductModel {
  final int id;
  final String name;
  final String? description;
  final double? primaryPrice;
  final double? primarySalePrice;
  final int? primaryStock;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<int> categoryIds;
  final String? categoryName;
  final int? brandId;
  final String? brandName;
  final bool isActive;
  final bool isFeatured;
  final String? unit;
  final List<String> tags;
  final int order;
  final List<ApiProductVariantModel> variants;

  // Koli varyant snapshot
  final String? koliVariantId;
  final double? koliPrice;
  final double? koliSalePrice;
  final int? koliStock;
  final int? koliPackageQty;

  const ApiProductModel({
    required this.id,
    required this.name,
    this.description,
    this.primaryPrice,
    this.primarySalePrice,
    this.primaryStock,
    this.imageUrl,
    this.imageUrls = const [],
    this.categoryIds = const [],
    this.categoryName,
    this.brandId,
    this.brandName,
    this.isActive = true,
    this.isFeatured = false,
    this.unit,
    this.tags = const [],
    this.order = 0,
    this.variants = const [],
    this.koliVariantId,
    this.koliPrice,
    this.koliSalePrice,
    this.koliStock,
    this.koliPackageQty,
  });

  factory ApiProductModel.fromJson(Map<String, dynamic> json) {
    // category_ids: list of int veya category_id: int
    List<int> parsedCategoryIds = [];
    if (json['category_ids'] != null) {
      parsedCategoryIds = List<int>.from(json['category_ids'] as List);
    } else if (json['category_id'] != null) {
      parsedCategoryIds = [json['category_id'] as int];
    }

    return ApiProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      primaryPrice: json['price'] != null
          ? (json['price'] as num).toDouble()
          : null,
      primarySalePrice: json['sale_price'] != null
          ? (json['sale_price'] as num).toDouble()
          : json['discounted_price'] != null
              ? (json['discounted_price'] as num).toDouble()
              : null,
      primaryStock: json['stock_quantity'] as int?,
      imageUrl: json['image_url'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : [],
      categoryIds: parsedCategoryIds,
      categoryName: json['category_name'] as String?,
      brandId: json['brand_id'] as int?,
      brandName: json['brand_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      unit: json['unit'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      order: json['order'] as int? ?? json['sort_order'] as int? ?? 0,
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) =>
                  ApiProductVariantModel.fromJson(v as Map<String, dynamic>))
              .toList()
          : [],
      koliVariantId: json['koli_variant_id']?.toString(),
      koliPrice: json['koli_price'] != null
          ? (json['koli_price'] as num).toDouble()
          : null,
      koliSalePrice: json['koli_sale_price'] != null
          ? (json['koli_sale_price'] as num).toDouble()
          : null,
      koliStock: json['koli_stock'] as int?,
      koliPackageQty: json['koli_package_qty'] as int?,
    );
  }

  ProductEntity toEntity() {
    final now = DateTime.now();
    return ProductEntity(
      id: id.toString(),
      name: name,
      description: description ?? '',
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      categoryIds: categoryIds.map((c) => c.toString()).toList(),
      brandId: brandId?.toString() ?? '',
      isActive: isActive,
      isFeatured: isFeatured,
      primaryPrice: primaryPrice,
      primarySalePrice: primarySalePrice,
      primaryStock: primaryStock,
      koliVariantId: koliVariantId,
      koliPrice: koliPrice,
      koliSalePrice: koliSalePrice,
      koliStock: koliStock,
      koliPackageQty: koliPackageQty,
      variants: variants.map((v) => v.toEntity()).toList(),
      tags: tags,
      order: order,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cache'e yazmak için sade map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': primaryPrice,
      'sale_price': primarySalePrice,
      'stock_quantity': primaryStock,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'category_ids': categoryIds,
      'category_name': categoryName,
      'brand_id': brandId,
      'brand_name': brandName,
      'is_active': isActive,
      'is_featured': isFeatured,
      'unit': unit,
      'tags': tags,
      'order': order,
    };
  }
}

class ApiProductVariantModel {
  final int id;
  final int? productId;
  final String name;
  final double price;
  final double? salePrice;
  final String unit;
  final int stock;
  final int minOrderQty;
  final int maxOrderQty;
  final int? packageQty;
  final bool isActive;
  final String? sku;
  final String? barcode;

  const ApiProductVariantModel({
    required this.id,
    this.productId,
    required this.name,
    required this.price,
    this.salePrice,
    this.unit = 'adet',
    this.stock = 0,
    this.minOrderQty = 1,
    this.maxOrderQty = 999,
    this.packageQty,
    this.isActive = true,
    this.sku,
    this.barcode,
  });

  factory ApiProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ApiProductVariantModel(
      id: json['id'] as int,
      productId: json['product_id'] as int?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      salePrice: json['sale_price'] != null
          ? (json['sale_price'] as num).toDouble()
          : json['discounted_price'] != null
              ? (json['discounted_price'] as num).toDouble()
              : null,
      unit: json['unit'] as String? ?? 'adet',
      stock: json['stock'] as int? ?? json['stock_quantity'] as int? ?? 0,
      minOrderQty: json['min_order_qty'] as int? ?? 1,
      maxOrderQty: json['max_order_qty'] as int? ?? 999,
      packageQty: json['package_qty'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
    );
  }

  ProductVariantEntity toEntity() {
    return ProductVariantEntity(
      id: id.toString(),
      productId: productId?.toString() ?? '',
      name: name,
      price: price,
      salePrice: salePrice,
      unit: unit,
      stock: stock,
      minOrderQty: minOrderQty,
      maxOrderQty: maxOrderQty,
      packageQty: packageQty,
      isActive: isActive,
      sku: sku,
      barcode: barcode,
    );
  }
}
