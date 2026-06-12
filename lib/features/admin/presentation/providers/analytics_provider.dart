import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/analytics_repository.dart';

// ---------------------------------------------------------------------------
// Rapor tipi enum
// ---------------------------------------------------------------------------
enum ReportType {
  dailySales,
  productPerformance,
  fieldAgentPerformance,
  customerAnalysis,
}

// ---------------------------------------------------------------------------
// Secili rapor tipi
// ---------------------------------------------------------------------------
class _ReportTypeNotifier extends Notifier<ReportType> {
  @override
  ReportType build() => ReportType.dailySales;

  void setType(ReportType type) => state = type;
}

final selectedReportTypeProvider =
    NotifierProvider<_ReportTypeNotifier, ReportType>(_ReportTypeNotifier.new);

// ---------------------------------------------------------------------------
// Rapor tarih araligi
// ---------------------------------------------------------------------------
class _ReportDateRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 29)),
      end: now,
    );
  }

  void setRange(DateTimeRange range) => state = range;
}

final reportDateRangeProvider =
    NotifierProvider<_ReportDateRangeNotifier, DateTimeRange>(
        _ReportDateRangeNotifier.new);

// ---------------------------------------------------------------------------
// Repository provider — API tabanlı implementasyon
// ---------------------------------------------------------------------------
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return ApiAnalyticsRepository(ref.read(apiClientProvider).dio);
});

// ---------------------------------------------------------------------------
// Excel export loading state
// ---------------------------------------------------------------------------
class _BoolNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

final excelExportLoadingProvider =
    NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);

// ---------------------------------------------------------------------------
// PDF export loading state
// ---------------------------------------------------------------------------
class _PdfBoolNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

final pdfExportLoadingProvider =
    NotifierProvider<_PdfBoolNotifier, bool>(_PdfBoolNotifier.new);

// ---------------------------------------------------------------------------
// Gunluk satis verileri — Firebase orders koleksiyonundan
// ---------------------------------------------------------------------------
final reportDailySalesProvider =
    FutureProvider<List<AnalyticsDailySalesData>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(reportDateRangeProvider);
  return repo.getDailySales(range);
});

// ---------------------------------------------------------------------------
// En cok satan urunler — Firebase orders'tan aggregate
// ---------------------------------------------------------------------------
final reportTopProductsProvider =
    FutureProvider<List<AnalyticsTopProductData>>((ref) {
  ref.watch(reportDateRangeProvider);
  return ref.watch(analyticsRepositoryProvider).getTopProducts(limit: 10);
});

// ---------------------------------------------------------------------------
// Müşteri buyumesi — Firebase users + orders koleksiyonundan
// ---------------------------------------------------------------------------
final reportCustomerGrowthProvider =
    FutureProvider<List<CustomerGrowthData>>((ref) {
  ref.watch(reportDateRangeProvider);
  return ref.watch(analyticsRepositoryProvider).getCustomerGrowth(months: 6);
});

// ---------------------------------------------------------------------------
// Saha personeli performansi — Firebase orders koleksiyonundan
// ---------------------------------------------------------------------------
final reportFieldAgentPerformanceProvider =
    FutureProvider<List<FieldAgentPerformanceData>>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(analyticsRepositoryProvider).getRevenueByFieldAgent(range);
});
