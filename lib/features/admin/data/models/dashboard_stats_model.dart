import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models/order_model.dart';

// Gunluk satis verisi (bar chart icin)
class DailySalesData {
  final DateTime date;
  final double amount;
  final int orderCount;

  const DailySalesData({
    required this.date,
    required this.amount,
    required this.orderCount,
  });
}

// Kategori satis dagilimi (pie chart icin)
class CategorySalesData {
  final String categoryName;
  final double amount;
  final int count;
  final String colorHex;

  const CategorySalesData({
    required this.categoryName,
    required this.amount,
    required this.count,
    required this.colorHex,
  });
}

// En cok satan urun
class TopProductData {
  final int rank;
  final String productId;
  final String productName;
  final int soldCount;
  final double totalRevenue;

  const TopProductData({
    required this.rank,
    required this.productId,
    required this.productName,
    required this.soldCount,
    required this.totalRevenue,
  });
}

// Son siparis ozet satiri
class RecentOrderSummary {
  final String id;
  final String orderNo;
  final String customerName;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;

  const RecentOrderSummary({
    required this.id,
    required this.orderNo,
    required this.customerName,
    required this.total,
    required this.status,
    required this.createdAt,
  });
}

// Firebase kullanim istatistigi
class FirebaseUsageStats {
  final int dailyReads;
  final int dailyWrites;
  final int dailyDeletes;
  final int dailyLimit;

  const FirebaseUsageStats({
    required this.dailyReads,
    required this.dailyWrites,
    required this.dailyDeletes,
    this.dailyLimit = 50000,
  });

  double get readUsagePercent => (dailyReads / dailyLimit).clamp(0.0, 1.0);

  bool get isNearLimit => readUsagePercent > 0.8;
}

// Ana dashboard veri modeli
class DashboardStats {
  final double dailySales;
  final double dailySalesChangePercent;
  final int totalOrders;
  final int activeCustomers;
  final FirebaseUsageStats firebaseUsage;
  final List<DailySalesData> weeklySales;
  final List<CategorySalesData> categorySales;
  final List<TopProductData> topProducts;
  final List<RecentOrderSummary> recentOrders;
  final DateTime generatedAt;

  const DashboardStats({
    required this.dailySales,
    required this.dailySalesChangePercent,
    required this.totalOrders,
    required this.activeCustomers,
    required this.firebaseUsage,
    required this.weeklySales,
    required this.categorySales,
    required this.topProducts,
    required this.recentOrders,
    required this.generatedAt,
  });

  factory DashboardStats.mock() {
    final now = DateTime.now();
    return DashboardStats(
      dailySales: 12450.0,
      dailySalesChangePercent: 8.5,
      totalOrders: 47,
      activeCustomers: 234,
      firebaseUsage: const FirebaseUsageStats(
        dailyReads: 12340,
        dailyWrites: 890,
        dailyDeletes: 45,
        dailyLimit: 50000,
      ),
      weeklySales: List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        const amounts = [8200.0, 9500.0, 7800.0, 11200.0, 10400.0, 13100.0, 12450.0];
        const counts = [32, 38, 29, 44, 41, 52, 47];
        return DailySalesData(
          date: day,
          amount: amounts[i],
          orderCount: counts[i],
        );
      }),
      categorySales: const [
        CategorySalesData(
          categoryName: 'Su',
          amount: 6800.0,
          count: 24,
          colorHex: '00A6AB',
        ),
        CategorySalesData(
          categoryName: 'Gazli',
          amount: 3200.0,
          count: 13,
          colorHex: 'E73A99',
        ),
        CategorySalesData(
          categoryName: 'Meyve Suyu',
          amount: 2450.0,
          count: 10,
          colorHex: '13275A',
        ),
      ],
      topProducts: const [
        TopProductData(
          rank: 1,
          productId: 'p001',
          productName: 'Erikli 19L Damacana',
          soldCount: 142,
          totalRevenue: 4260.0,
        ),
        TopProductData(
          rank: 2,
          productId: 'p002',
          productName: 'Coca-Cola 2.5L (6li Koli)',
          soldCount: 89,
          totalRevenue: 2670.0,
        ),
        TopProductData(
          rank: 3,
          productId: 'p003',
          productName: 'Solan 0.5L (12li Koli)',
          soldCount: 76,
          totalRevenue: 1520.0,
        ),
        TopProductData(
          rank: 4,
          productId: 'p004',
          productName: 'Dimes Seftali 1L (8li)',
          soldCount: 54,
          totalRevenue: 1350.0,
        ),
        TopProductData(
          rank: 5,
          productId: 'p005',
          productName: 'Beypazari 1.5L (6li Koli)',
          soldCount: 48,
          totalRevenue: 1200.0,
        ),
      ],
      recentOrders: [
        RecentOrderSummary(
          id: 'ord001',
          orderNo: 'NT-2024-0047',
          customerName: 'Ahmet Yilmaz',
          total: 450.0,
          status: OrderStatus.delivered,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        RecentOrderSummary(
          id: 'ord002',
          orderNo: 'NT-2024-0046',
          customerName: 'Fatma Kaya',
          total: 280.0,
          status: OrderStatus.onTheWay,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        RecentOrderSummary(
          id: 'ord003',
          orderNo: 'NT-2024-0045',
          customerName: 'Mehmet Demir',
          total: 620.0,
          status: OrderStatus.preparing,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        RecentOrderSummary(
          id: 'ord004',
          orderNo: 'NT-2024-0044',
          customerName: 'Zeynep Arslan',
          total: 190.0,
          status: OrderStatus.confirmed,
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        RecentOrderSummary(
          id: 'ord005',
          orderNo: 'NT-2024-0043',
          customerName: 'Ali Celik',
          total: 340.0,
          status: OrderStatus.pending,
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        RecentOrderSummary(
          id: 'ord006',
          orderNo: 'NT-2024-0042',
          customerName: 'Elif Sahin',
          total: 760.0,
          status: OrderStatus.cancelled,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        RecentOrderSummary(
          id: 'ord007',
          orderNo: 'NT-2024-0041',
          customerName: 'Hasan Ozturk',
          total: 520.0,
          status: OrderStatus.delivered,
          createdAt: now.subtract(const Duration(hours: 7)),
        ),
        RecentOrderSummary(
          id: 'ord008',
          orderNo: 'NT-2024-0040',
          customerName: 'Ayse Yildiz',
          total: 150.0,
          status: OrderStatus.delivered,
          createdAt: now.subtract(const Duration(hours: 8)),
        ),
      ],
      generatedAt: now,
    );
  }

  /// Firestore'dan çekilen siparişlerden dashboard istatistikleri türet.
  /// [orders]: Son 7 günün siparişleri (createdAt desc sıralı).
  factory DashboardStats.fromOrders(List<OrderModel> orders, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    bool isToday(DateTime d) => !d.isBefore(todayStart);
    bool isYesterday(DateTime d) =>
        !d.isBefore(yesterdayStart) && d.isBefore(todayStart);

    final todayOrders = orders.where((o) => isToday(o.createdAt));
    final yesterdayOrders = orders.where((o) => isYesterday(o.createdAt));

    final dailySales = todayOrders.fold<double>(0, (s, o) => s + o.total);
    final yesterdaySales =
        yesterdayOrders.fold<double>(0, (s, o) => s + o.total);
    final changePercent = yesterdaySales == 0
        ? 0.0
        : (dailySales - yesterdaySales) / yesterdaySales * 100;

    // Haftalık grafik — her gün için toplam
    final weeklySales = List.generate(7, (i) {
      final dayStart = todayStart.subtract(Duration(days: 6 - i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayOrders = orders.where((o) =>
          !o.createdAt.isBefore(dayStart) && o.createdAt.isBefore(dayEnd));
      return DailySalesData(
        date: dayStart,
        amount: dayOrders.fold(0, (s, o) => s + o.total),
        orderCount: dayOrders.length,
      );
    });

    // En çok satan ürünler — sipariş kalemlerinden aggregate
    final productSales =
        <String, ({String name, int count, double revenue})>{};
    for (final order in orders) {
      for (final item in order.items) {
        final prev = productSales[item.productId];
        productSales[item.productId] = (
          name: item.productName,
          count: (prev?.count ?? 0) + item.qty,
          revenue: (prev?.revenue ?? 0) + item.totalPrice,
        );
      }
    }
    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final topProducts = sortedProducts.take(5).toList().asMap().entries.map(
      (e) => TopProductData(
        rank: e.key + 1,
        productId: e.value.key,
        productName: e.value.value.name,
        soldCount: e.value.value.count,
        totalRevenue: e.value.value.revenue,
      ),
    ).toList();

    // Son 10 sipariş
    final recentOrders = orders.take(10).map((o) => RecentOrderSummary(
          id: o.id,
          orderNo: o.orderNo,
          customerName: o.customerName,
          total: o.total,
          status: o.status,
          createdAt: o.createdAt,
        )).toList();

    // Aktif müşteriler — son 7 günde sipariş veren unique ID sayısı
    final activeCustomers = orders.map((o) => o.customerId).toSet().length;

    // Aktif (teslim edilmemiş, iptal edilmemiş) sipariş sayısı
    final totalOrders = orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
        .length;

    return DashboardStats(
      dailySales: dailySales,
      dailySalesChangePercent: changePercent,
      totalOrders: totalOrders,
      activeCustomers: activeCustomers,
      firebaseUsage: const FirebaseUsageStats(
        dailyReads: 0,
        dailyWrites: 0,
        dailyDeletes: 0,
      ),
      weeklySales: weeklySales,
      categorySales: const [], // Sipariş modelinde kategori yok
      topProducts: topProducts,
      recentOrders: recentOrders,
      generatedAt: now,
    );
  }

  /// API /v1/admin/analytics/dashboard yanıtından dashboard istatistikleri oluşturur.
  /// Defensive parse — her field null check ile.
  factory DashboardStats.fromApiJson(Map<String, dynamic> json, DateTime now) {
    final todaySales = (json['today_revenue'] as num? ?? 0).toDouble();
    final totalOrdersVal = (json['total_orders'] as num? ?? 0).toInt();
    final activeCustomersVal = (json['total_customers'] as num? ?? 0).toInt();

    // Haftalık satış grafiği
    List<DailySalesData> weeklySales = [];
    final weeklyRaw = json['weekly_orders'];
    if (weeklyRaw is List) {
      weeklySales = weeklyRaw.map((raw) {
        final j = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final dateStr = j['date'] as String? ?? '';
        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = now;
        }
        return DailySalesData(
          date: date,
          amount: (j['revenue'] as num? ?? j['total'] as num? ?? 0).toDouble(),
          orderCount: (j['count'] as num? ?? j['order_count'] as num? ?? 0).toInt(),
        );
      }).toList();
    }

    // En çok satan ürünler
    List<TopProductData> topProducts = [];
    final topRaw = json['top_products'];
    if (topRaw is List) {
      topProducts = topRaw.asMap().entries.map((entry) {
        final j = entry.value is Map<String, dynamic>
            ? entry.value as Map<String, dynamic>
            : <String, dynamic>{};
        return TopProductData(
          rank: entry.key + 1,
          productId: (j['product_id'] as int? ?? 0).toString(),
          productName: j['product_name'] as String? ?? '',
          soldCount: (j['total_quantity'] as num? ?? 0).toInt(),
          totalRevenue: (j['total_revenue'] as num? ?? 0).toDouble(),
        );
      }).toList();
    }

    // Son siparişler
    List<RecentOrderSummary> recentOrders = [];
    final recentRaw = json['recent_orders'];
    if (recentRaw is List) {
      recentOrders = recentRaw.map((raw) {
        final j = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final statusStr = j['status'] as String? ?? 'pending';
        final status = _parseOrderStatus(statusStr);
        final dateStr = j['created_at'] as String? ?? '';
        DateTime createdAt;
        try {
          createdAt = DateTime.parse(dateStr);
        } catch (_) {
          createdAt = now;
        }
        return RecentOrderSummary(
          id: (j['id'] as int? ?? 0).toString(),
          orderNo: j['order_number'] as String? ?? j['order_no'] as String? ?? '',
          customerName: j['customer_name'] as String? ?? '',
          total: (j['total'] as num? ?? 0).toDouble(),
          status: status,
          createdAt: createdAt,
        );
      }).toList();
    }

    return DashboardStats(
      dailySales: todaySales,
      dailySalesChangePercent: 0.0, // API bu alanı henüz döndürmüyor
      totalOrders: totalOrdersVal,
      activeCustomers: activeCustomersVal,
      firebaseUsage: const FirebaseUsageStats(
        dailyReads: 0,
        dailyWrites: 0,
        dailyDeletes: 0,
      ),
      weeklySales: weeklySales,
      categorySales: const [],
      topProducts: topProducts,
      recentOrders: recentOrders,
      generatedAt: now,
    );
  }
}

OrderStatus _parseOrderStatus(String s) {
  switch (s) {
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'on_the_way':
      return OrderStatus.onTheWay;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}
