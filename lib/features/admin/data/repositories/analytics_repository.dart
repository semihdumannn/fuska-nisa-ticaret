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

  /// Firebase kullanim istatistiklerini getirir.
  Future<FirebaseUsageData> getFirebaseUsage();

  /// Verilen tarih araligina ait kategori bazli satis dagilimini getirir.
  Future<List<CategoryDistributionData>> getCategoryDistribution(
      DateTimeRange dateRange);

  /// Verilen tarih araligina ait saha personeli performansini getirir.
  Future<List<FieldAgentPerformanceData>> getRevenueByFieldAgent(
      DateTimeRange dateRange);

  /// Tum analytics verilerini paralel olarak cekmek icin kolaylik metodu.
  Future<AnalyticsReport> getFullReport(DateTimeRange dateRange);
}

// ---------------------------------------------------------------------------
// Mock implementasyon — UI gelistirmesi icin gercekci sentetik veri uretir.
// Firebase implementasyonu hazir olunca bu sinifi [FirebaseAnalyticsRepository]
// ile degistirmek yeterlidir; provider katmaninda tek satirlik degisiklik yapilir.
// ---------------------------------------------------------------------------
class MockAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<List<AnalyticsDailySalesData>> getDailySales(
      DateTimeRange dateRange) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final days = dateRange.end.difference(dateRange.start).inDays + 1;

    return List.generate(days, (i) {
      final date = dateRange.start.add(Duration(days: i));
      final isWeekend = date.weekday >= 6;

      // Hafta sonlari daha dusuk, hafta ici daha yuksek satis
      final revenue =
          isWeekend ? 800.0 + (i * 50 % 400) : 1500.0 + (i * 80 % 800);
      final orderCount = isWeekend ? 8 + (i % 5) : 15 + (i % 10);

      return AnalyticsDailySalesData(
        date: date,
        revenue: revenue,
        orderCount: orderCount,
        averageOrderValue: revenue / orderCount,
      );
    });
  }

  @override
  Future<List<AnalyticsTopProductData>> getTopProducts({
    int limit = 10,
    DateTimeRange? dateRange,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Nisa Ticaret urun katalogundan olusturulmus gercekci mock veri
    final allProducts = [
      const AnalyticsTopProductData(
        productId: 'p001',
        productName: 'Erikli 19L Damacana',
        categoryName: 'Su',
        totalQuantity: 284,
        totalRevenue: 12780.0,
        revenueShare: 0.31,
      ),
      const AnalyticsTopProductData(
        productId: 'p002',
        productName: 'Coca-Cola 2.5L (6li Koli)',
        categoryName: 'Gazli Icecek',
        totalQuantity: 178,
        totalRevenue: 8012.0,
        revenueShare: 0.20,
      ),
      const AnalyticsTopProductData(
        productId: 'p003',
        productName: 'Solan 0.5L (12li Koli)',
        categoryName: 'Su',
        totalQuantity: 152,
        totalRevenue: 6080.0,
        revenueShare: 0.15,
      ),
      const AnalyticsTopProductData(
        productId: 'p004',
        productName: 'Dimes Seftali 1L (8li)',
        categoryName: 'Meyve Suyu',
        totalQuantity: 108,
        totalRevenue: 4860.0,
        revenueShare: 0.12,
      ),
      const AnalyticsTopProductData(
        productId: 'p005',
        productName: 'Beypazari 1.5L (6li Koli)',
        categoryName: 'Su',
        totalQuantity: 96,
        totalRevenue: 3840.0,
        revenueShare: 0.09,
      ),
      const AnalyticsTopProductData(
        productId: 'p006',
        productName: 'Fanta Portakal 1L (6li)',
        categoryName: 'Gazli Icecek',
        totalQuantity: 74,
        totalRevenue: 2960.0,
        revenueShare: 0.07,
      ),
      const AnalyticsTopProductData(
        productId: 'p007',
        productName: 'Cappy Karisik 1L',
        categoryName: 'Meyve Suyu',
        totalQuantity: 58,
        totalRevenue: 2030.0,
        revenueShare: 0.05,
      ),
      const AnalyticsTopProductData(
        productId: 'p008',
        productName: 'Sprite 0.5L (24lu Koli)',
        categoryName: 'Gazli Icecek',
        totalQuantity: 42,
        totalRevenue: 840.0,
        revenueShare: 0.02,
      ),
      const AnalyticsTopProductData(
        productId: 'p009',
        productName: 'Erikli 0.33L (24lu Koli)',
        categoryName: 'Su',
        totalQuantity: 36,
        totalRevenue: 504.0,
        revenueShare: 0.01,
      ),
      const AnalyticsTopProductData(
        productId: 'p010',
        productName: 'Kuzey Buz Cay Seftali 1L',
        categoryName: 'Soguk Cay',
        totalQuantity: 28,
        totalRevenue: 392.0,
        revenueShare: 0.01,
      ),
    ];

    return allProducts.take(limit).toList();
  }

  @override
  Future<List<CustomerGrowthData>> getCustomerGrowth({int months = 6}) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final now = DateTime.now();
    int cumulativeCustomers = 180; // baslangic toplam müşteri sayisi

    return List.generate(months, (i) {
      // En eskiden en yeniye dogru: [months-1 ay once, ..., bu ay]
      final monthOffset = months - 1 - i;
      final date = DateTime(now.year, now.month - monthOffset, 1);

      // Her ay biraz artan yeni müşteri sayisi (buyume egri simulasyonu)
      final newCustomers = 18 + (i * 4) + (i % 3 == 0 ? 8 : 0);
      cumulativeCustomers += newCustomers;

      // Aktif müşteriler yeni müşteri + onceki ay aktif müşterilerin %60'i
      final activeCustomers = (newCustomers + (cumulativeCustomers * 0.22)).round();

      return CustomerGrowthData(
        date: date,
        newCustomers: newCustomers,
        totalCustomers: cumulativeCustomers,
        activeCustomers: activeCustomers,
      );
    });
  }

  @override
  Future<FirebaseUsageData> getFirebaseUsage() async {
    await Future.delayed(const Duration(milliseconds: 150));

    // Spark Plan: 50.000 okuma/gun, 20.000 yazma/gun
    const dailyReads = 12340;
    const dailyWrites = 450;

    return const FirebaseUsageData(
      totalReads: 125000,
      totalWrites: 8500,
      dailyReads: dailyReads,
      dailyWrites: dailyWrites,
      monthlyReads: 285000,
      monthlyWrites: 12000,
      readLimitPercent: dailyReads / 50000, // 0.2468
      writeLimitPercent: dailyWrites / 20000, // 0.0225
    );
  }

  @override
  Future<List<CategoryDistributionData>> getCategoryDistribution(
      DateTimeRange dateRange) async {
    await Future.delayed(const Duration(milliseconds: 200));

    const totalRevenue = 41066.0;

    return const [
      CategoryDistributionData(
        categoryId: 'cat_su',
        categoryName: 'Su',
        orderCount: 156,
        revenue: 23204.0,
        revenueShare: 23204.0 / totalRevenue, // ~0.565
      ),
      CategoryDistributionData(
        categoryId: 'cat_gazli',
        categoryName: 'Gazli Icecek',
        orderCount: 94,
        revenue: 11812.0,
        revenueShare: 11812.0 / totalRevenue, // ~0.288
      ),
      CategoryDistributionData(
        categoryId: 'cat_meyve',
        categoryName: 'Meyve Suyu',
        orderCount: 66,
        revenue: 4890.0,
        revenueShare: 4890.0 / totalRevenue, // ~0.119
      ),
      CategoryDistributionData(
        categoryId: 'cat_soguk_cay',
        categoryName: 'Soguk Cay',
        orderCount: 22,
        revenue: 1160.0,
        revenueShare: 1160.0 / totalRevenue, // ~0.028
      ),
    ];
  }

  @override
  Future<List<FieldAgentPerformanceData>> getRevenueByFieldAgent(
      DateTimeRange dateRange) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return const [
      FieldAgentPerformanceData(
        agentId: 'agent1',
        agentName: 'Mehmet Kaya',
        totalOrders: 87,
        totalRevenue: 18640.0,
        averageOrderValue: 214.25,
        customersServed: 52,
      ),
      FieldAgentPerformanceData(
        agentId: 'agent2',
        agentName: 'Hasan Celik',
        totalOrders: 74,
        totalRevenue: 15230.0,
        averageOrderValue: 205.81,
        customersServed: 44,
      ),
      FieldAgentPerformanceData(
        agentId: 'agent3',
        agentName: 'Kadir Yildiz',
        totalOrders: 58,
        totalRevenue: 11480.0,
        averageOrderValue: 197.93,
        customersServed: 35,
      ),
    ];
  }

  @override
  Future<AnalyticsReport> getFullReport(DateTimeRange dateRange) async {
    // Tum veri kumelerini paralel olarak cek
    final results = await Future.wait([
      getDailySales(dateRange),
      getTopProducts(),
      getCustomerGrowth(),
      getFirebaseUsage(),
      getCategoryDistribution(dateRange),
      getRevenueByFieldAgent(dateRange),
    ]);

    return AnalyticsReport(
      dateRange: dateRange,
      dailySales: results[0] as List<AnalyticsDailySalesData>,
      topProducts: results[1] as List<AnalyticsTopProductData>,
      customerGrowth: results[2] as List<CustomerGrowthData>,
      firebaseUsage: results[3] as FirebaseUsageData,
      categoryDistribution: results[4] as List<CategoryDistributionData>,
      fieldAgentPerformance: results[5] as List<FieldAgentPerformanceData>,
    );
  }
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
  Future<FirebaseUsageData> getFirebaseUsage() async {
    final key = _dateKey(DateTime.now());
    final doc = await _firestore.collection('_usage').doc(key).get();
    if (!doc.exists) {
      return const FirebaseUsageData(
        totalReads: 0, totalWrites: 0,
        dailyReads: 0, dailyWrites: 0,
        monthlyReads: 0, monthlyWrites: 0,
        readLimitPercent: 0, writeLimitPercent: 0,
      );
    }
    final d = doc.data()!;
    final r = (d['reads'] as num? ?? 0).toInt();
    final w = (d['writes'] as num? ?? 0).toInt();
    return FirebaseUsageData(
      totalReads: r, totalWrites: w,
      dailyReads: r, dailyWrites: w,
      monthlyReads: r, monthlyWrites: w,
      readLimitPercent: (r / 50000).clamp(0.0, 1.0),
      writeLimitPercent: (w / 20000).clamp(0.0, 1.0),
    );
  }

  @override
  Future<List<CategoryDistributionData>> getCategoryDistribution(
      DateTimeRange dateRange) async {
    final orderSnap = await _queryOrders(dateRange);

    final productIds = <String>{};
    final allItems = <Map<String, dynamic>>[];
    for (final doc in orderSnap.docs) {
      for (final raw in doc.data()['items'] as List<dynamic>? ?? []) {
        final item = raw as Map<String, dynamic>;
        allItems.add(item);
        final pid = item['productId'] as String?;
        if (pid != null && pid.isNotEmpty) productIds.add(pid);
      }
    }

    // productId → categoryId eşlemesi
    final pidCatMap = <String, String>{};
    final pidList = productIds.toList();
    for (int i = 0; i < pidList.length; i += 30) {
      final chunk =
          pidList.sublist(i, (i + 30).clamp(0, pidList.length));
      final snap = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        pidCatMap[doc.id] =
            doc.data()['categoryId'] as String? ?? 'other';
      }
    }

    // Kategori isimlerini çek
    final catSnap = await _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .get();
    final catNames = <String, String>{
      for (final doc in catSnap.docs)
        doc.id: doc.data()['name'] as String? ?? doc.id,
    };

    final catMap = <String, ({String name, int count, double revenue})>{};
    double totalRevenue = 0;
    for (final item in allItems) {
      final pid = item['productId'] as String? ?? '';
      final catId = pidCatMap[pid] ?? 'other';
      final catName = catNames[catId] ?? catId;
      final rev = (item['totalPrice'] as num? ?? 0).toDouble();
      final prev = catMap[catId];
      catMap[catId] = (
        name: catName,
        count: (prev?.count ?? 0) + 1,
        revenue: (prev?.revenue ?? 0) + rev,
      );
      totalRevenue += rev;
    }

    return (catMap.entries.map((e) => CategoryDistributionData(
          categoryId: e.key,
          categoryName: e.value.name,
          orderCount: e.value.count,
          revenue: e.value.revenue,
          revenueShare:
              totalRevenue > 0 ? e.value.revenue / totalRevenue : 0,
        )).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue)));
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

  @override
  Future<AnalyticsReport> getFullReport(DateTimeRange dateRange) async {
    final results = await Future.wait([
      getDailySales(dateRange),
      getTopProducts(),
      getCustomerGrowth(),
      getFirebaseUsage(),
      getCategoryDistribution(dateRange),
      getRevenueByFieldAgent(dateRange),
    ]);
    return AnalyticsReport(
      dateRange: dateRange,
      dailySales: results[0] as List<AnalyticsDailySalesData>,
      topProducts: results[1] as List<AnalyticsTopProductData>,
      customerGrowth: results[2] as List<CustomerGrowthData>,
      firebaseUsage: results[3] as FirebaseUsageData,
      categoryDistribution: results[4] as List<CategoryDistributionData>,
      fieldAgentPerformance: results[5] as List<FieldAgentPerformanceData>,
    );
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
  Future<FirebaseUsageData> getFirebaseUsage() async {
    // Firebase kullanım istatistiği API'de yok — const sıfır döndür
    return const FirebaseUsageData(
      totalReads: 0,
      totalWrites: 0,
      dailyReads: 0,
      dailyWrites: 0,
      monthlyReads: 0,
      monthlyWrites: 0,
      readLimitPercent: 0.0,
      writeLimitPercent: 0.0,
    );
  }

  @override
  Future<List<CategoryDistributionData>> getCategoryDistribution(
      DateTimeRange dateRange) async {
    // NOT: Backend'de urun kategorisine gore satis dagilimi donduren bir
    // endpoint yok. Gecici olarak siparis-durumu dagilimi (order-statuses)
    // kullanilir; categoryId/categoryName alanlarina durum (status/label)
    // yerlestirilir. 'revenue' alani backend'den gelmez, bu yuzden 0 doner.
    try {
      final response = await _dio.get(
        ApiEndpoints.adminAnalyticsOrderStatuses,
        queryParameters: {
          'from': _fmt(dateRange.start),
          'to': _fmt(dateRange.end),
        },
      );
      final rawList = _extractList(response.data);
      if (rawList.isEmpty) return [];

      final items = rawList.map((raw) {
        final j = raw as Map<String, dynamic>;
        final count = (j['count'] as num? ?? 0).toInt();
        final percentage = (j['percentage'] as num? ?? 0).toDouble();
        return _RawCategoryDist(
          id: j['status'] as String? ?? '',
          name: j['label'] as String? ?? (j['status'] as String? ?? ''),
          count: count,
          revenue: 0.0,
          revenueShare: percentage / 100.0,
        );
      }).toList();

      return items
          .map((c) => CategoryDistributionData(
                categoryId: c.id,
                categoryName: c.name,
                orderCount: c.count,
                revenue: c.revenue,
                revenueShare: c.revenueShare,
              ))
          .toList();
    } on DioException {
      return [];
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

  @override
  Future<AnalyticsReport> getFullReport(DateTimeRange dateRange) async {
    final results = await Future.wait([
      getDailySales(dateRange),
      getTopProducts(dateRange: dateRange),
      getCustomerGrowth(),
      getFirebaseUsage(),
      getCategoryDistribution(dateRange),
      getRevenueByFieldAgent(dateRange),
    ]);

    return AnalyticsReport(
      dateRange: dateRange,
      dailySales: results[0] as List<AnalyticsDailySalesData>,
      topProducts: results[1] as List<AnalyticsTopProductData>,
      customerGrowth: results[2] as List<CustomerGrowthData>,
      firebaseUsage: results[3] as FirebaseUsageData,
      categoryDistribution: results[4] as List<CategoryDistributionData>,
      fieldAgentPerformance: results[5] as List<FieldAgentPerformanceData>,
    );
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

class _RawCategoryDist {
  final String id;
  final String name;
  final int count;
  final double revenue;
  final double revenueShare;
  const _RawCategoryDist({
    required this.id,
    required this.name,
    required this.count,
    required this.revenue,
    this.revenueShare = 0.0,
  });
}
