import 'package:equatable/equatable.dart';

/// Müşteri bilgilerini temsil eden domain entity.
/// Firebase veya herhangi bir dış bağımlılık içermez — pure Dart.
class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final DateTime? lastOrderDate;
  final double totalSpent;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    this.lastOrderDate,
    required this.totalSpent,
  });

  /// Müşterinin daha önce sipariş verip vermediğini kontrol eder.
  bool get hasOrders => lastOrderDate != null;

  /// Müşterinin görüntüleme adı — kırpılmış.
  String get displayName => name.trim();

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        notes,
        lastOrderDate,
        totalSpent,
      ];
}
