import 'package:flutter/material.dart';

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
// Firebase kullanim verisi — Spark plan limitlerine gore izleme
// Spark Plan limitleri: 50.000 okuma/gun, 20.000 yazma/gun
// ---------------------------------------------------------------------------
class FirebaseUsageData {
  final int totalReads;
  final int totalWrites;
  final int dailyReads;
  final int dailyWrites;
  final int monthlyReads;
  final int monthlyWrites;

  /// dailyReads / 50000 (0.0 - 1.0)
  final double readLimitPercent;

  /// dailyWrites / 20000 (0.0 - 1.0)
  final double writeLimitPercent;

  const FirebaseUsageData({
    required this.totalReads,
    required this.totalWrites,
    required this.dailyReads,
    required this.dailyWrites,
    required this.monthlyReads,
    required this.monthlyWrites,
    required this.readLimitPercent,
    required this.writeLimitPercent,
  });

  /// Gunluk okuma limitine yakin mi? (%80 esigi)
  bool get isReadNearLimit => readLimitPercent > 0.8;

  /// Gunluk yazma limitine yakin mi? (%80 esigi)
  bool get isWriteNearLimit => writeLimitPercent > 0.8;

  /// Kullanim durumunu renk olarak dondur
  Color get readStatusColor {
    if (readLimitPercent > 0.9) return const Color(0xFFF44336); // kirmizi
    if (readLimitPercent > 0.7) return const Color(0xFFFF9800); // turuncu
    return const Color(0xFF43A047); // yesil
  }
}

// ---------------------------------------------------------------------------
// Kategori bazli satis dagilimi
// ---------------------------------------------------------------------------
class CategoryDistributionData {
  final String categoryId;
  final String categoryName;
  final int orderCount;
  final double revenue;

  /// 0.0 - 1.0 araliginda, toplam ciro icerisindeki pay
  final double revenueShare;

  const CategoryDistributionData({
    required this.categoryId,
    required this.categoryName,
    required this.orderCount,
    required this.revenue,
    required this.revenueShare,
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

// ---------------------------------------------------------------------------
// Tam analytics raporu — tum veri kumelerini birlestiren sinif
// ---------------------------------------------------------------------------
class AnalyticsReport {
  final DateTimeRange dateRange;
  final List<AnalyticsDailySalesData> dailySales;
  final List<AnalyticsTopProductData> topProducts;
  final List<CustomerGrowthData> customerGrowth;
  final FirebaseUsageData firebaseUsage;
  final List<CategoryDistributionData> categoryDistribution;
  final List<FieldAgentPerformanceData> fieldAgentPerformance;

  const AnalyticsReport({
    required this.dateRange,
    required this.dailySales,
    required this.topProducts,
    required this.customerGrowth,
    required this.firebaseUsage,
    required this.categoryDistribution,
    required this.fieldAgentPerformance,
  });

  /// Tarih araligindaki toplam ciro
  double get totalRevenue =>
      dailySales.fold(0.0, (sum, d) => sum + d.revenue);

  /// Tarih araligindaki toplam siparis adedi
  int get totalOrders =>
      dailySales.fold(0, (sum, d) => sum + d.orderCount);

  /// Ortalama siparis degeri
  double get averageOrderValue =>
      totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
}
