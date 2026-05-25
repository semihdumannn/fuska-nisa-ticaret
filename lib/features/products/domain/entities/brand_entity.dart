import 'package:equatable/equatable.dart';

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

  @override
  List<Object?> get props => [id, name, slug, isActive, order];
}
