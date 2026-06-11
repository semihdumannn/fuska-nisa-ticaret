import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  final String id;
  final String userId;
  final String label;
  final String fullAddress;
  final String district;
  final String city;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final String? notes;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullAddress,
    required this.district,
    required this.city,
    this.lat,
    this.lng,
    this.isDefault = false,
    this.notes,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      label: json['label'] ?? 'Diğer',
      fullAddress: json['fullAddress'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isDefault: json['isDefault'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'fullAddress': fullAddress,
      'district': district,
      'city': city,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
      'notes': notes,
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? fullAddress,
    String? district,
    String? city,
    double? lat,
    double? lng,
    bool? isDefault,
    String? notes,
    bool clearLat = false,
    bool clearLng = false,
    bool clearNotes = false,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      district: district ?? this.district,
      city: city ?? this.city,
      lat: clearLat ? null : (lat ?? this.lat),
      lng: clearLng ? null : (lng ?? this.lng),
      isDefault: isDefault ?? this.isDefault,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  @override
  List<Object?> get props => [id];
}
