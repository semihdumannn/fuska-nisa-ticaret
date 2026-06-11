import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String iconName;
  final String? iconAsset; // SVG asset yolu, null ise iconName kullanılır
  final String color;
  final int sortOrder;
  final bool isActive;
  final String? parentId; // null = kök kategori
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconName,
    this.iconAsset,
    required this.color,
    required this.sortOrder,
    required this.isActive,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRoot => parentId == null || parentId!.isEmpty;

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'iconName': iconName,
      'iconAsset': iconAsset,
      'color': color,
      'sortOrder': sortOrder,
      'isActive': isActive,
      if (parentId != null) 'parentId': parentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? iconName,
    String? iconAsset,
    String? color,
    int? sortOrder,
    bool? isActive,
    Object? parentId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      iconName: iconName ?? this.iconName,
      iconAsset: iconAsset ?? this.iconAsset,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      parentId: parentId == _sentinel ? this.parentId : parentId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
