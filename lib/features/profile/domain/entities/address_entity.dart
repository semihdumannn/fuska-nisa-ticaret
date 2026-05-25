import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  final int? id;
  final String title; // 'Ev', 'Is', 'Diger'
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

  const AddressEntity({
    this.id,
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

  String get fullAddress {
    final parts = [
      addressLine,
      if (neighborhood != null) neighborhood,
      if (district != null) district,
      city,
    ];
    return parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  AddressEntity copyWith({
    int? id,
    String? title,
    String? fullName,
    String? phone,
    String? addressLine,
    String? city,
    String? district,
    String? neighborhood,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return AddressEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [id, title, addressLine, city, isDefault];
}
