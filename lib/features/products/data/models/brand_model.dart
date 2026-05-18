import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory BrandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BrandModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      slug: data['slug'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      order: (data['order'] as num? ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      order: (json['order'] as num? ?? 0).toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logoUrl': logoUrl,
      'description': description,
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'logoUrl': logoUrl,
      'description': description,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

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
