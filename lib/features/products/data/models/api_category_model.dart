import '../../domain/entities/category_entity.dart';

/// Laravel Resource Collection veya düz array olarak gelen children'ı parse et.
List<ApiCategoryModel> _parseChildren(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return raw
        .map((c) => ApiCategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }
  // Laravel Resource Collection: {"data": [...]}
  if (raw is Map && raw.containsKey('data') && raw['data'] is List) {
    return (raw['data'] as List)
        .map((c) => ApiCategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }
  return const [];
}

class ApiCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String iconName;
  final String? iconAsset;
  final String color;
  final int? parentId;
  final List<ApiCategoryModel> children;
  final int productCount;
  final bool isActive;
  final int sortOrder;

  const ApiCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.iconName = '',
    this.iconAsset,
    this.color = '#000000',
    this.parentId,
    this.children = const [],
    this.productCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ApiCategoryModel.fromJson(Map<String, dynamic> json) {
    return ApiCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      iconName: json['icon'] as String? ?? json['icon_name'] as String? ?? '',
      iconAsset: json['icon_asset'] as String?,
      color: json['color'] as String? ?? '#000000',
      parentId: json['parent_id'] as int?,
      children: _parseChildren(json['children']),
      productCount:
          json['products_count'] as int? ?? json['product_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id.toString(),
      name: name,
      slug: slug,
      description: description,
      imageUrl: imageUrl,
      iconName: iconName,
      iconAsset: iconAsset,
      color: color,
      parentId: parentId?.toString(),
      children: children.map((c) => c.toEntity()).toList(),
      productCount: productCount,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }
}
