import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String iconName;
  final String? iconAsset;
  final String color;
  final String? parentId;
  final List<CategoryEntity> children;
  final int productCount;
  final bool isActive;
  final int sortOrder;

  const CategoryEntity({
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

  bool get hasChildren => children.isNotEmpty;

  bool get isRoot => parentId == null || parentId!.isEmpty;

  @override
  List<Object?> get props => [id, name, slug, parentId, isActive, sortOrder];
}
