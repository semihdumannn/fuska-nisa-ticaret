import 'package:equatable/equatable.dart';

class BrandModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  BrandModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? logoUrl,
    bool clearLogoUrl = false,
    String? description,
    bool clearDescription = false,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      description: clearDescription ? null : (description ?? this.description),
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, isActive, order];
}
