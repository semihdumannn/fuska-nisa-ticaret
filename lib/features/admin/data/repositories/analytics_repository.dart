import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/analytics_model.dart';

// ---------------------------------------------------------------------------
// Soyut repository arayuzu
// ---------------------------------------------------------------------------
abstract class AnalyticsRepository {
  /// Verilen tarih araligina ait gunluk satis verilerini getirir.
  Future<List<AnalyticsDailySalesData>> getDailySales(DateTimeRange dateRange);

  /// En cok satan [limit] adet urunu getirir.
  /// [dateRange] verilirse o araliga gore filtrelenir (API implementasyonu);
  /// verilmezse implementasyona gore varsayilan (orn. son 30 gun) kullanilir.
  Future<List<AnalyticsTopProductData>> getTopProducts({
    int limit = 10,
    DateTimeRange? dateRange,
  });

  /// Son [months] aya ait müşteri buyume verisini getirir.
  Future<List<CustomerGrowthData>> getCustomerGrowth({int months = 6});

  /// Verilen tarih araligina ait saha personeli performansini getirir.
  Future<List<FieldAgentPerformanceData>> getRevenueByFieldAgent(
      DateTimeRange dateRange);
}

// ---------------------------------------------------------------------------
// API implementasyonu — HF Space REST API üzerinden analytics
// ---------------------------------------------------------------------------
class ApiAnalyticsRepository implements AnalyticsRepository {
  final Dio _dio;

  ApiAnalyticsRepository(this._dio);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<AnalyticsDailySalesData>> getDailySales(
      DateTimeRange dateRange) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.adminAnalyticsRevenue,
        queryParameters: {
          'from': _fmt(dateRange.start),
          'to': _fmt(dateRange.end),
        },
      );
      final rawList = _extractList(response.data);
      return rawList.map((raw) {
        final j = raw as Map<String, dynamic>;
        final dateStr = j['date'] as String? ?? '';
        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = dateRange.start;
        }
        // Backend (GetRevenueReportUseCase) 'revenue' ve 'orders' alanlarını dondurur.
        final revenue = (j['revenue'] as num? ?? 0).toDouble();
        final orderCount = (j['orders'] as num? ?? 0).toInt();
        return AnalyticsDailySalesData(
          date: date,
          revenue: revenue,
          orderCount: orderCount,
          averageOrderValue: orderCount > 0 ? revenue / orderCount : 0.0,
        );
      }).toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<AnalyticsTopProductData>> getTopProducts(
      {int limit = 10, DateTimeRange? dateRange}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.adminAnalyticsTopProducts,
        queryParameters: {
          'limit': limit,
          if (dateRange != null) ...{
            'from': _fmt(dateRange.start),
            'to': _fmt(dateRange.end),
          },
        },
      );
      final rawList = _extractList(response.data);
      double totalRevenue = 0;
      // Backend (GetTopProductsUseCase) 'category_name' / 'revenue_share' dondurmuyor;
      // bu nedenle revenueShare burada toplam uzerinden hesaplaniyor,
      // categoryName bos birakiliyor (UI'da gosterilmiyorsa sorun degil).
      final parsed = rawList.map((raw) {
        final j = raw as Map<String, dynamic>;
        final rev = (j['total_revenue'] as num? ?? 0).toDouble();
        totalRevenue += rev;
        return _RawTopProduct(
          productId: (j['product_id'] as int? ?? 0).toString(),
          productName: j['product_name'] as String? ?? '',
          categoryName: j['category_name'] as String? ?? '',
          totalQuantity: (j['total_quantity'] as num? ?? 0).toInt(),
          totalRevenue: rev,
          revenueShare: (j['revenue_share'] as num? ?? 0).toDouble(),
        );
      }).toList();

      return parsed.map((p) {
        final share = p.revenueShare > 0
            ? p.revenueShare
            : (totalRevenue > 0 ? p.totalRevenue / totalRevenue : 0.0);
        return AnalyticsTopProductData(
          productId: p.productId,
          productName: p.productName,
          categoryName: p.categoryName,
          totalQuantity: p.totalQuantity,
          totalRevenue: p.totalRevenue,
          revenueShare: share,
        );
      }).toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<CustomerGrowthData>> getCustomerGrowth({int months = 6}) async {
    // top-customers endpoint müşteri büyümesi vermez; basit tahmin üret
    try {
      final response = await _dio.get(
        ApiEndpoints.adminAnalyticsTopCustomers,
        queryParameters: {'limit': 50},
      );
      final rawList = _extractList(response.data);
      final now = DateTime.now();
      final totalCustomers = rawList.length;
      return List.generate(months, (i) {
        final monthOffset = months - 1 - i;
        final date = DateTime(now.year, now.month - monthOffset, 1);
        final estimatedNew =
            totalCustomers > 0 ? (totalCustomers / months).round() : 0;
        return CustomerGrowthData(
          date: date,
          newCustomers: estimatedNew,
          totalCustomers: estimatedNew * (i + 1),
          activeCustomers: (estimatedNew * 0.7).round(),
        );
      });
    } on DioException {
      final now = DateTime.now();
      return List.generate(months, (i) {
        final monthOffset = months - 1 - i;
        return CustomerGrowthData(
          date: DateTime(now.year, now.month - monthOffset, 1),
          newCustomers: 0,
          totalCustomers: 0,
          activeCustomers: 0,
        );
      });
    }
  }

  @override
  Future<List<FieldAgentPerformanceData>> getRevenueByFieldAgent(
      DateTimeRange dateRange) async {
    // API'de saha personeli performans endpoint'i yok.
    // Firestore bağımlılığı kaldırıldığından boş liste döndürülür.
    // İleride API endpoint eklendiğinde burası güncellenmeli.
    return [];
  }

  /// API yanıtından `data` listesini çıkar (Laravel Resource Collection veya düz list).
  List<dynamic> _extractList(dynamic body) {
    if (body == null) return [];
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'];
      if (data is List) return data;
    }
    return [];
  }
}

// Dahili yardımcı sınıflar
class _RawTopProduct {
  final String productId;
  final String productName;
  final String categoryName;
  final int totalQuantity;
  final double totalRevenue;
  final double revenueShare;
  const _RawTopProduct({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.revenueShare,
  });
}
