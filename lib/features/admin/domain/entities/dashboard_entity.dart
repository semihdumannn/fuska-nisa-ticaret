import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int totalOrders;
  final int pendingOrders;
  final int todayOrders;
  final double totalRevenue;
  final double todayRevenue;
  final int totalCustomers;
  final int totalProducts;
  final int lowStockProducts;

  const DashboardStatsEntity({
    required this.totalOrders,
    required this.pendingOrders,
    required this.todayOrders,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.totalCustomers,
    required this.totalProducts,
    required this.lowStockProducts,
  });

  @override
  List<Object?> get props => [totalOrders, totalRevenue, todayOrders];
}

class DailySalesEntity extends Equatable {
  final DateTime date;
  final double amount;
  final int orderCount;

  const DailySalesEntity({
    required this.date,
    required this.amount,
    required this.orderCount,
  });

  @override
  List<Object?> get props => [date, amount];
}

class TopProductEntity extends Equatable {
  final int rank;
  final String productId;
  final String productName;
  final int soldCount;
  final double totalRevenue;

  const TopProductEntity({
    required this.rank,
    required this.productId,
    required this.productName,
    required this.soldCount,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [productId, soldCount];
}
