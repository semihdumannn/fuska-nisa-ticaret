import 'package:equatable/equatable.dart';

/// Saha personelinin günlük sipariş istatistiklerini temsil eden domain entity.
/// Firebase veya herhangi bir dış bağımlılık içermez — pure Dart.
class FieldAgentStatsEntity extends Equatable {
  final int totalOrders;
  final int pendingOrders;
  final int preparingOrders;
  final int onTheWayOrders;
  final int deliveredOrders;
  final double totalSales;

  const FieldAgentStatsEntity({
    required this.totalOrders,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.onTheWayOrders,
    required this.deliveredOrders,
    required this.totalSales,
  });

  /// Sıfır değerlerle başlatılmış boş istatistik nesnesi.
  static const empty = FieldAgentStatsEntity(
    totalOrders: 0,
    pendingOrders: 0,
    preparingOrders: 0,
    onTheWayOrders: 0,
    deliveredOrders: 0,
    totalSales: 0.0,
  );

  /// Teslimat tamamlanma oranı (0.0 - 1.0).
  double get completionRate =>
      totalOrders == 0 ? 0.0 : deliveredOrders / totalOrders;

  @override
  List<Object?> get props => [
        totalOrders,
        pendingOrders,
        preparingOrders,
        onTheWayOrders,
        deliveredOrders,
        totalSales,
      ];
}
