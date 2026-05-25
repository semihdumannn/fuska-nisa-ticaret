import 'package:cloud_firestore/cloud_firestore.dart';
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
    if (koliVariantId != null) return (koliStock ?? 0) > 0;
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

  // ─── Factory constructors ─────────────────────────────────────────────────

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      brandId: data['brandId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      categoryIds: _parseCategoryIds(data),
      imageUrl: data['imageUrl'] as String?,
      imageUrls: _parseStringList(data['imageUrls']),
      tags: _parseStringList(data['tags']),
      isActive: data['isActive'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      order: (data['order'] as num? ?? 0).toInt(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      primaryPrice: (data['price'] as num?)?.toDouble(),
      primarySalePrice: (data['salePrice'] as num?)?.toDouble(),
      primaryStock: (data['stock'] as num?)?.toInt(),
      koliVariantId: data['koliVariantId'] as String?,
      koliPrice: (data['koliPrice'] as num?)?.toDouble(),
      koliSalePrice: (data['koliSalePrice'] as num?)?.toDouble(),
      koliStock: (data['koliStock'] as num?)?.toInt(),
      koliPackageQty: (data['koliPackageQty'] as num?)?.toInt(),
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      brandId: json['brandId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryIds: _parseCategoryIds(json),
      imageUrl: json['imageUrl'] as String?,
      imageUrls: _parseStringList(json['imageUrls']),
      tags: _parseStringList(json['tags']),
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      order: (json['order'] as num? ?? 0).toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      primaryPrice: (json['price'] as num?)?.toDouble(),
      primarySalePrice: (json['salePrice'] as num?)?.toDouble(),
      primaryStock: (json['stock'] as num?)?.toInt(),
      koliVariantId: json['koliVariantId'] as String?,
      koliPrice: (json['koliPrice'] as num?)?.toDouble(),
      koliSalePrice: (json['koliSalePrice'] as num?)?.toDouble(),
      koliStock: (json['koliStock'] as num?)?.toInt(),
      koliPackageQty: (json['koliPackageQty'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'description': description,
      'categoryIds': categoryIds,
      'categoryId': categoryIds.isNotEmpty ? categoryIds.first : '',
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'tags': tags,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'price': primaryPrice,
      'salePrice': primarySalePrice,
      'stock': primaryStock,
      'koliVariantId': koliVariantId,
      'koliPrice': koliPrice,
      'koliSalePrice': koliSalePrice,
      'koliStock': koliStock,
      'koliPackageQty': koliPackageQty,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'brandId': brandId,
      'name': name,
      'description': description,
      'categoryIds': categoryIds,
      'categoryId': categoryIds.isNotEmpty ? categoryIds.first : '',
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'tags': tags,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (primaryPrice != null) 'price': primaryPrice,
      if (primarySalePrice != null) 'salePrice': primarySalePrice,
      if (primaryStock != null) 'stock': primaryStock,
      if (koliVariantId != null) 'koliVariantId': koliVariantId,
      if (koliPrice != null) 'koliPrice': koliPrice,
      if (koliSalePrice != null) 'koliSalePrice': koliSalePrice,
      if (koliStock != null) 'koliStock': koliStock,
      if (koliPackageQty != null) 'koliPackageQty': koliPackageQty,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.whereType<String>().toList();
    return [];
  }

  static List<String> _parseCategoryIds(Map<String, dynamic> data) {
    // Yeni format: categoryIds array
    final ids = data['categoryIds'];
    if (ids is List && ids.isNotEmpty) {
      return ids.whereType<String>().toList();
    }
    // Eski format: tek categoryId string
    final single = data['categoryId'] as String?;
    if (single != null && single.isNotEmpty) return [single];
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
