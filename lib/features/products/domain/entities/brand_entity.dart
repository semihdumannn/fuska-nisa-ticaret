import 'package:equatable/equatable.dart';
import 'package:nisa_ticaret/features/products/data/models/brand_model.dart';

class BrandEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final bool isActive;
  final int order;
  final int productCount;

  const BrandEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    this.isActive = true,
    this.order = 0,
    this.productCount = 0,
  });

  BrandModel toBrandModel() => BrandModel(
        id: id,
        name: name,
        slug: slug,
        logoUrl: logoUrl,
        description: description,
        isActive: isActive,
        order: order,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  @override
  List<Object?> get props => [id, name, slug, isActive, order];
}
