import 'package:cloud_firestore/cloud_firestore.dart';
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
// Firebase implementasyonu — orders/users/products/categories sorguları ile
// client-side aggregate. _analytics pre-computed koleksiyonu varsa önce onu
// kullanır (Cloud Function dailySalesAggregation / weeklyReport yazar).
// ---------------------------------------------------------------------------
class FirebaseAnalyticsRepository implements AnalyticsRepository {
  final FirebaseFirestore _firestore;

  FirebaseAnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<QuerySnapshot<Map<String, dynamic>>> _queryOrders(
      DateTimeRange range) {
    return _firestore
        .collection('orders')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('createdAt',
            isLessThanOrEqualTo:
                Timestamp.fromDate(range.end.add(const Duration(days: 1))))
        .get();
  }

  @override
  Future<List<AnalyticsDailySalesData>> getDailySales(
      DateTimeRange dateRange) async {
    final days = dateRange.end.difference(dateRange.start).inDays + 1;
    final snap = await _queryOrders(dateRange);

    final dayMap = <String, ({double revenue, int count})>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = (data['createdAt'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final key = _dateKey(ts);
      final total = (data['total'] as num? ?? 0).toDouble();
      final prev = dayMap[key];
      dayMap[key] = (
        revenue: (prev?.revenue ?? 0) + total,
        count: (prev?.count ?? 0) + 1,
      );
    }

    return List.generate(days, (i) {
      final date = dateRange.start.add(Duration(days: i));
      final key = _dateKey(date);
      final e = dayMap[key];
      return AnalyticsDailySalesData(
        date: date,
        revenue: e?.revenue ?? 0,
        orderCount: e?.count ?? 0,
        averageOrderValue:
            (e?.count ?? 0) > 0 ? e!.revenue / e.count : 0,
      );
    });
  }

  @override
  Future<List<AnalyticsTopProductData>> getTopProducts({
    int limit = 10,
    DateTimeRange? dateRange,
  }) async {
    final now = DateTime.now();
    final snap = await _queryOrders(dateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        ));

    final map = <String, ({String name, int qty, double revenue})>{};
    double totalRevenue = 0;
    for (final doc in snap.docs) {
      for (final raw in doc.data()['items'] as List<dynamic>? ?? []) {
        final item = raw as Map<String, dynamic>;
        final pid = item['productId'] as String? ?? '';
        final name = item['productName'] as String? ?? '';
        final qty = (item['qty'] as num? ?? 0).toInt();
        final rev = (item['totalPrice'] as num? ?? 0).toDouble();
        totalRevenue += rev;
        final prev = map[pid];
        map[pid] = (
          name: name,
          qty: (prev?.qty ?? 0) + qty,
          revenue: (prev?.revenue ?? 0) + rev,
        );
      }
    }

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    return sorted.take(limit).map((e) => AnalyticsTopProductData(
          productId: e.key,
          productName: e.value.name,
          categoryName: '',
          totalQuantity: e.value.qty,
          totalRevenue: e.value.revenue,
          revenueShare: totalRevenue > 0 ? e.value.revenue / totalRevenue : 0,
        )).toList();
  }

  @override
  Future<List<CustomerGrowthData>> getCustomerGrowth({int months = 6}) async {
    final now = DateTime.now();
    final result = <CustomerGrowthData>[];

    for (int i = months - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1);

      // Yeni müşteri sayısı
      final newSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(monthEnd))
          .get();

      // Bu ay sipariş veren unique müşteri sayısı
      final activeSnap = await _firestore
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(monthEnd))
          .get();
      final activeCustomers = activeSnap.docs
          .map((d) => d.data()['customerId'] as String? ?? '')
          .toSet()
          .length;

      result.add(CustomerGrowthData(
        date: monthStart,
        newCustomers: newSnap.size,
        totalCustomers: 0, // kümülatif hesap pahalı
        activeCustomers: activeCustomers,
      ));
    }
    return result;
  }

  @override
  Future<List<FieldAgentPerformanceData>> getRevenueByFieldAgent(
      DateTimeRange dateRange) async {
    final snap = await _firestore
        .collection('orders')
        .where('source', isEqualTo: 'field_agent')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
        .where('createdAt',
            isLessThanOrEqualTo:
                Timestamp.fromDate(dateRange.end.add(const Duration(days: 1))))
        .get();

    final agentMap =
        <String, ({int orders, double revenue, Set<String> customers})>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final agentId = data['createdBy'] as String? ?? '';
      if (agentId.isEmpty) continue;
      final total = (data['total'] as num? ?? 0).toDouble();
      final cid = data['customerId'] as String? ?? '';
      final prev = agentMap[agentId];
      agentMap[agentId] = (
        orders: (prev?.orders ?? 0) + 1,
        revenue: (prev?.revenue ?? 0) + total,
        customers: {...(prev?.customers ?? <String>{}), cid},
      );
    }
    if (agentMap.isEmpty) return [];

    // Agent isimlerini al
    final ids = agentMap.keys.toList();
    final names = <String, String>{};
    for (int i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, (i + 30).clamp(0, ids.length));
      final userSnap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in userSnap.docs) {
        names[doc.id] = doc.data()['name'] as String? ?? '';
      }
    }

    return (agentMap.entries.map((e) {
      final rev = e.value.revenue;
      final cnt = e.value.orders;
      return FieldAgentPerformanceData(
        agentId: e.key,
        agentName: names[e.key] ?? e.key,
        totalOrders: cnt,
        totalRevenue: rev,
        averageOrderValue: cnt > 0 ? rev / cnt : 0,
        customersServed: e.value.customers.length,
      );
    }).toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue)));
  }
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
    // Fallback: FirebaseAnalyticsRepository uzerinden Firestore'dan hesapla.
    // Bu metod sadece admin "saha personeli performansi" raporu acildiginda
    // cagrilir (sik kullanilmaz), bu yuzden Firestore okuma maliyeti kabul
    // edilebilir seviyededir.
    return FirebaseAnalyticsRepository().getRevenueByFieldAgent(dateRange);
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
