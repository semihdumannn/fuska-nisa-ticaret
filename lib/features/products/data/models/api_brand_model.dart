import '../../domain/entities/brand_entity.dart';

class ApiBrandModel {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final bool isActive;
  final int order;
  final int productCount;

  const ApiBrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    this.isActive = true,
    this.order = 0,
    this.productCount = 0,
  });

  factory ApiBrandModel.fromJson(Map<String, dynamic> json) {
    return ApiBrandModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      order: json['order'] as int? ?? json['sort_order'] as int? ?? 0,
      productCount:
          json['products_count'] as int? ?? json['product_count'] as int? ?? 0,
    );
  }

  BrandEntity toEntity() {
    return BrandEntity(
      id: id.toString(),
      name: name,
      slug: slug,
      logoUrl: logoUrl,
      description: description,
      isActive: isActive,
      order: order,
      productCount: productCount,
    );
  }
}
