import '../../domain/entities/address_entity.dart';

class ApiAddressModel {
  final int id;
  final String title;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String? district;
  final String? neighborhood;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const ApiAddressModel({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    this.district,
    this.neighborhood,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory ApiAddressModel.fromJson(Map<String, dynamic> json) {
    return ApiAddressModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Adres',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine:
          json['address_line'] as String? ?? json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      neighborhood: json['neighborhood'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'full_name': fullName,
      'phone': phone,
      'address_line': addressLine,
      'city': city,
      if (district != null) 'district': district,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (postalCode != null) 'postal_code': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default': isDefault,
    };
  }

  AddressEntity toEntity() {
    return AddressEntity(
      id: id,
      title: title,
      fullName: fullName,
      phone: phone,
      addressLine: addressLine,
      city: city,
      district: district,
      neighborhood: neighborhood,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }

  static Map<String, dynamic> entityToJson(AddressEntity entity) {
    return {
      'title': entity.title,
      'full_name': entity.fullName,
      'phone': entity.phone,
      'address_line': entity.addressLine,
      'city': entity.city,
      if (entity.district != null) 'district': entity.district,
      if (entity.neighborhood != null) 'neighborhood': entity.neighborhood,
      if (entity.postalCode != null) 'postal_code': entity.postalCode,
      if (entity.latitude != null) 'latitude': entity.latitude,
      if (entity.longitude != null) 'longitude': entity.longitude,
      'is_default': entity.isDefault,
    };
  }
}
