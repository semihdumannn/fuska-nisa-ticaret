// ---------------------------------------------------------------------------
// Gunluk satis verisi — analytics raporu icin (DateTimeRange bazli)
// NOT: dashboard_stats_model.dart'taki DailySalesData dashboard'a ozgudur.
// Bu model daha kapsamli analytics amaclariyla kullanilir.
// ---------------------------------------------------------------------------
class AnalyticsDailySalesData {
  final DateTime date;
  final double revenue;
  final int orderCount;
  final double averageOrderValue;

  const AnalyticsDailySalesData({
    required this.date,
    required this.revenue,
    required this.orderCount,
    required this.averageOrderValue,
  });
}

// ---------------------------------------------------------------------------
// En cok satan urun — analytics raporu icin
// NOT: dashboard_stats_model.dart'taki TopProductData rank iceren, dashboard'a ozgudur.
// Bu model revenueShare (pasta payi) ve kategori bilgisi icermektedir.
// ---------------------------------------------------------------------------
class AnalyticsTopProductData {
  final String productId;
  final String productName;
  final String categoryName;
  final int totalQuantity;
  final double totalRevenue;

  /// 0.0 - 1.0 araliginda, toplam ciro icerisindeki pay
  final double revenueShare;

  const AnalyticsTopProductData({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.revenueShare,
  });
}

// ---------------------------------------------------------------------------
// Müşteri buyumesi — aylik yeni/toplam/aktif müşteri sayilari
// ---------------------------------------------------------------------------
class CustomerGrowthData {
  final DateTime date;

  /// Ay icerisinde ilk kez kayit olan müşteri sayisi
  final int newCustomers;

  /// Kumulatif toplam müşteri sayisi
  final int totalCustomers;

  /// Ilgili ay icerisinde en az bir siparis veren müşteri sayisi
  final int activeCustomers;

  const CustomerGrowthData({
    required this.date,
    required this.newCustomers,
    required this.totalCustomers,
    required this.activeCustomers,
  });
}

// ---------------------------------------------------------------------------
// Saha personeli performansi
// ---------------------------------------------------------------------------
class FieldAgentPerformanceData {
  final String agentId;
  final String agentName;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int customersServed;

  const FieldAgentPerformanceData({
    required this.agentId,
    required this.agentName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.customersServed,
  });
}
