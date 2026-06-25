import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/analytics_model.dart';
import '../../data/services/report_export_service.dart';
import '../providers/analytics_provider.dart';
import '../widgets/admin_sidebar.dart';

// ---------------------------------------------------------------------------
// Kisaltma sabitleri
// ---------------------------------------------------------------------------
const double _kDesktop = 1024.0;
const double _kTablet = 700.0;

final _currencyFmt = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);
final _dateFmt = DateFormat('dd MMM', 'tr_TR');
final _fullDateFmt = DateFormat('dd.MM.yyyy');

// ---------------------------------------------------------------------------
// Ekran girisi
// ---------------------------------------------------------------------------
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktop;

    if (isDesktop) {
      return const _DesktopLayout();
    }
    return const _MobileLayout();
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AdminSidebar(),
          Expanded(child: _ReportsContent()),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawerWrapper(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        title: const Text(
          'Raporlar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: const _ReportsContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Icerik — ScrollView + tab yonetimi
// ---------------------------------------------------------------------------
class _ReportsContent extends ConsumerWidget {
  const _ReportsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktop;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ReportsHeader(),
          SizedBox(height: 20),
          _ReportTypeTabs(),
          SizedBox(height: 20),
          _ActiveTabContent(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: başlık + tarih seçici + export butonları
// ---------------------------------------------------------------------------
class _ReportsHeader extends ConsumerWidget {
  const _ReportsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(reportDateRangeProvider);
    final excelLoading = ref.watch(excelExportLoadingProvider);
    final pdfLoading = ref.watch(pdfExportLoadingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baslik
        const Text(
          'Raporlar',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Satis, urun ve müşteri analizleri',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 12),

        // Aksiyon butonları — tam genişlik, wrap ile aşağıya geçer
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Tarih Araligi Butonu
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDateRange: dateRange,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        secondary: AppColors.secondary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  ref
                      .read(reportDateRangeProvider.notifier)
                      .setRange(picked);
                }
              },
              icon: const Icon(Icons.date_range_outlined, size: 16),
              label: Text(
                '${_dateFmt.format(dateRange.start)} - '
                '${_dateFmt.format(dateRange.end)}',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(0, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                side: const BorderSide(color: AppColors.border),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Excel export butonu
            _ExportButton(
              label: 'CSV Indir',
              icon: Icons.table_chart_outlined,
              color: AppColors.excelGreen,
              isLoading: excelLoading,
              onPressed: () => _onExcelExport(ref, context),
            ),

            // PDF / TXT export butonu
            _ExportButton(
              label: 'Rapor Indir',
              icon: Icons.picture_as_pdf_outlined,
              color: AppColors.pdfRed,
              isLoading: pdfLoading,
              onPressed: () => _onPdfExport(ref, context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onExcelExport(WidgetRef ref, BuildContext context) async {
    ref.read(excelExportLoadingProvider.notifier).toggle(true);
    try {
      final service = ref.read(reportExportServiceProvider);
      final sales =
          ref.read(reportDailySalesProvider).value ?? [];
      final products =
          ref.read(reportTopProductsProvider).value ?? [];
      final agents =
          ref.read(reportFieldAgentPerformanceProvider).value ?? [];
      final dateRange = ref.read(reportDateRangeProvider);
      await service.exportToCsv(
        salesData: sales,
        products: products,
        agents: agents,
        dateRange: dateRange,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV oluşturma hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      ref.read(excelExportLoadingProvider.notifier).toggle(false);
    }
  }

  Future<void> _onPdfExport(WidgetRef ref, BuildContext context) async {
    ref.read(pdfExportLoadingProvider.notifier).toggle(true);
    try {
      final service = ref.read(reportExportServiceProvider);
      final sales =
          ref.read(reportDailySalesProvider).value ?? [];
      final products =
          ref.read(reportTopProductsProvider).value ?? [];
      final dateRange = ref.read(reportDateRangeProvider);
      await service.exportSummaryAsTxt(
        salesData: sales,
        products: products,
        dateRange: dateRange,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor olusturma hatasi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      ref.read(pdfExportLoadingProvider.notifier).toggle(false);
    }
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            )
          : Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab secim bari
// ---------------------------------------------------------------------------
class _ReportTypeTabs extends ConsumerWidget {
  const _ReportTypeTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedReportTypeProvider);

    final tabs = [
      (ReportType.dailySales, 'Gunluk Satis', Icons.show_chart),
      (ReportType.productPerformance, 'Urun Performansi', Icons.inventory_2_outlined),
      (ReportType.fieldAgentPerformance, 'Saha Performansi', Icons.person_pin_outlined),
      (ReportType.customerAnalysis, 'Müşteri Analizi', Icons.people_outline),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isActive = selected == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _TabChip(
              label: tab.$2,
              icon: tab.$3,
              isActive: isActive,
              onTap: () => ref
                  .read(selectedReportTypeProvider.notifier)
                  .setType(tab.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aktif tab icerigi
// ---------------------------------------------------------------------------
class _ActiveTabContent extends ConsumerWidget {
  const _ActiveTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(selectedReportTypeProvider);
    switch (type) {
      case ReportType.dailySales:
        return const _DailySalesTab();
      case ReportType.productPerformance:
        return const _ProductPerformanceTab();
      case ReportType.fieldAgentPerformance:
        return const _FieldAgentTab();
      case ReportType.customerAnalysis:
        return const _CustomerAnalysisTab();
    }
  }
}

// ===========================================================================
// TAB 1 — GUNLUK SATIS RAPORU
// ===========================================================================
class _DailySalesTab extends ConsumerWidget {
  const _DailySalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(reportDailySalesProvider);

    return salesAsync.when(
      loading: () => const _ReportShimmer(height: 520),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (sales) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ozet kartlar
          _SummaryGrid(sales: sales),
          const SizedBox(height: 20),
          // Cizgi grafik
          _SalesLineChart(sales: sales),
          const SizedBox(height: 20),
          // Detay tablo
          _SalesDetailTable(sales: sales),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<AnalyticsDailySalesData> sales;

  const _SummaryGrid({required this.sales});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width >= _kDesktop ? 4 : (width >= _kTablet ? 2 : 2);

    if (sales.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalRevenue = sales.fold(0.0, (s, d) => s + d.revenue);
    final totalOrders = sales.fold(0, (s, d) => s + d.orderCount);
    final avgDaily = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;
    final bestDay =
        sales.reduce((a, b) => a.revenue > b.revenue ? a : b);

    final cards = [
      _SummaryCardData(
        title: 'Toplam Gelir',
        value: _currencyFmt.format(totalRevenue),
        icon: Icons.attach_money_rounded,
        iconColor: AppColors.success,
        iconBgColor: AppColors.success.withValues(alpha: 0.12),
      ),
      _SummaryCardData(
        title: 'Toplam Siparis',
        value: '$totalOrders adet',
        icon: Icons.shopping_bag_outlined,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primary.withValues(alpha: 0.12),
      ),
      _SummaryCardData(
        title: 'Ortalama Gunluk',
        value: _currencyFmt.format(avgDaily),
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.accent,
        iconBgColor: AppColors.accent.withValues(alpha: 0.12),
      ),
      _SummaryCardData(
        title: 'En Iyi Gun',
        value: _fullDateFmt.format(bestDay.date),
        subtitle: _currencyFmt.format(bestDay.revenue),
        icon: Icons.star_outline_rounded,
        iconColor: AppColors.warning,
        iconBgColor: AppColors.warning.withValues(alpha: 0.12),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: width >= _kDesktop ? 1.6 : 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _SummaryCard(data: cards[i]),
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _SummaryCardData({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 18),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (data.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              data.subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Satis Cizgi Grafigi (fl_chart LineChart)
// ---------------------------------------------------------------------------
class _SalesLineChart extends StatelessWidget {
  final List<AnalyticsDailySalesData> sales;

  const _SalesLineChart({required this.sales});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return const SizedBox.shrink();

    final maxY =
        sales.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);
    final spots = sales.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.revenue);
    }).toList();

    // Gosteilen etiket araligi
    final step = (sales.length / 6).ceil();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Gunluk Satis Grafigi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _LegendDot(color: AppColors.primary, label: 'Gelir (TL)'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.25,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.secondary,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx < 0 || idx >= sales.length) {
                          return null;
                        }
                        final d = sales[idx];
                        return LineTooltipItem(
                          '${_dateFmt.format(d.date)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: _currencyFmt.format(d.revenue),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: '\n${d.orderCount} siparis',
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1.0,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: step > 0 ? step.toDouble() : 1.0,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 ||
                            idx >= sales.length ||
                            idx % step != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _dateFmt.format(sales[idx].date),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: maxY > 0 ? maxY / 4 : 1.0,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _formatAmount(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: spots.length <= 14,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.20),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ---------------------------------------------------------------------------
// Satis Detay Tablosu
// ---------------------------------------------------------------------------
class _SalesDetailTable extends StatelessWidget {
  final List<AnalyticsDailySalesData> sales;

  const _SalesDetailTable({required this.sales});

  @override
  Widget build(BuildContext context) {
    final reversed = sales.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Gunluk Detay',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tablo basligi
          Container(
            color: AppColors.adminBackground,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('Tarih')),
                Expanded(flex: 3, child: _TableHeader('Gelir')),
                Expanded(flex: 2, child: _TableHeader('Siparis')),
                Expanded(flex: 3, child: _TableHeader('Ort. Siparis')),
                Expanded(flex: 2, child: _TableHeader('Degisim')),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversed.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) {
              final day = reversed[i];
              double changePercent = 0;
              if (i + 1 < reversed.length) {
                final prev = reversed[i + 1].revenue;
                if (prev > 0) {
                  changePercent =
                      ((day.revenue - prev) / prev) * 100;
                }
              }
              return _SalesTableRow(
                day: day,
                changePercent: i + 1 < reversed.length
                    ? changePercent
                    : null,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SalesTableRow extends StatelessWidget {
  final AnalyticsDailySalesData day;
  final double? changePercent;

  const _SalesTableRow({required this.day, this.changePercent});

  @override
  Widget build(BuildContext context) {
    final isUp = changePercent != null && changePercent! >= 0;
    final changeColor = changePercent == null
        ? AppColors.textHint
        : (isUp ? AppColors.success : AppColors.error);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _fullDateFmt.format(day.date),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _currencyFmt.format(day.revenue),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${day.orderCount}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _currencyFmt.format(day.averageOrderValue),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: changePercent == null
                ? const Text('—',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textHint))
                : Row(
                    children: [
                      Icon(
                        isUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '%${changePercent!.abs().toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TAB 2 — URUN PERFORMANSI
// ===========================================================================
class _ProductPerformanceTab extends ConsumerWidget {
  const _ProductPerformanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(reportTopProductsProvider);

    return productsAsync.when(
      loading: () => const _ReportShimmer(height: 520),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (products) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductBarChart(products: products),
          const SizedBox(height: 20),
          _ProductTable(products: products),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yatay Bar Chart — en cok satan urunler
// ---------------------------------------------------------------------------
class _ProductBarChart extends StatelessWidget {
  final List<AnalyticsTopProductData> products;

  const _ProductBarChart({required this.products});

  static const Map<String, Color> _catColors = {
    'Su': AppColors.accent,
    'Gazli': AppColors.primary,
    'Meyve Suyu': AppColors.secondary,
    'Gazli Icecek': AppColors.primary,
  };

  Color _colorFor(String cat) =>
      _catColors[cat] ?? AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final top8 = products.take(8).toList();
    final maxQty = top8
        .map((p) => p.totalQuantity)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'En Cok Satan Urunler (Adet)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: top8.length * 50.0 + 20,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.start,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.secondary,
                    getTooltipItem:
                        (group, groupIndex, rod, rodIndex) {
                      final p = top8[group.x];
                      return BarTooltipItem(
                        '${p.productName}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: '${p.totalQuantity} adet',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 130,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= top8.length) {
                          return const SizedBox.shrink();
                        }
                        final name = top8[idx].productName;
                        final short = name.length > 18
                            ? '${name.substring(0, 16)}...'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            short,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: maxQty > 0 ? maxQty / 4 : 1.0,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: false,
                  verticalInterval: maxQty > 0 ? maxQty / 4 : 1.0,
                  getDrawingVerticalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: maxQty * 1.15,
                barGroups: top8.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: p.totalQuantity.toDouble(),
                        color: _colorFor(p.categoryName),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxQty * 1.15,
                          color: AppColors.border
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(height: 12),
          // Renk aciklamasi
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: _catColors.entries.map((e) {
              return _LegendDot(color: e.value, label: e.key);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Urun Performans Tablosu
// ---------------------------------------------------------------------------
class _ProductTable extends StatelessWidget {
  final List<AnalyticsTopProductData> products;

  const _ProductTable({required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Urun Detaylari',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: AppColors.adminBackground,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                SizedBox(width: 32, child: _TableHeader('#')),
                Expanded(flex: 4, child: _TableHeader('Urun')),
                Expanded(flex: 2, child: _TableHeader('Kategori')),
                Expanded(flex: 2, child: _TableHeader('Adet')),
                Expanded(flex: 3, child: _TableHeader('Gelir')),
                Expanded(flex: 4, child: _TableHeader('Gelir Payi')),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) =>
                _ProductTableRow(rank: i + 1, product: products[i]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProductTableRow extends StatelessWidget {
  final int rank;
  final AnalyticsTopProductData product;

  const _ProductTableRow(
      {required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              product.productName,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: _CategoryBadge(name: product.categoryName),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${product.totalQuantity}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _currencyFmt.format(product.totalRevenue),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '%${(product.revenueShare * 100).toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: product.revenueShare,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String name;

  const _CategoryBadge({required this.name});

  static const Map<String, Color> _colors = {
    'Su': AppColors.accent,
    'Gazli': AppColors.primary,
    'Meyve Suyu': AppColors.secondary,
    'Gazli Icecek': AppColors.primary,
    'Diger': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[name] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ===========================================================================
// TAB 3 — SAHA PERSONELI PERFORMANSI
// ===========================================================================
class _FieldAgentTab extends ConsumerWidget {
  const _FieldAgentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(reportFieldAgentPerformanceProvider);

    return agentsAsync.when(
      loading: () => const _ReportShimmer(height: 400),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (agents) {
        if (agents.isEmpty) {
          return const _EmptyCard(
              message: 'Saha performans verisi bulunamadı.');
        }
        final maxRevenue =
            agents.map((a) => a.totalRevenue).reduce((a, b) => a > b ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performans kartlari grid
            _AgentCardsGrid(agents: agents, maxRevenue: maxRevenue),
            const SizedBox(height: 20),
            // Karsilastirma tablosu
            _AgentComparisonTable(agents: agents),
          ],
        );
      },
    );
  }
}

class _AgentCardsGrid extends StatelessWidget {
  final List<FieldAgentPerformanceData> agents;
  final double maxRevenue;

  const _AgentCardsGrid(
      {required this.agents, required this.maxRevenue});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width >= _kDesktop ? 4 : (width >= _kTablet ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: crossCount == 1 ? 2.0 : 1.2,
      ),
      itemCount: agents.length,
      itemBuilder: (_, i) => _AgentCard(
        agent: agents[i],
        maxRevenue: maxRevenue,
        rank: i + 1,
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final FieldAgentPerformanceData agent;
  final double maxRevenue;
  final int rank;

  const _AgentCard({
    required this.agent,
    required this.maxRevenue,
    required this.rank,
  });

  static const List<Color> _rankColors = [
    AppColors.warning, // altin
    AppColors.textHint, // gumus
    AppColors.medalBronze, // bronz
    AppColors.accent,
  ];

  @override
  Widget build(BuildContext context) {
    final barFill =
        maxRevenue > 0 ? (agent.totalRevenue / maxRevenue) : 0.0;
    final rankColor =
        rank <= _rankColors.length ? _rankColors[rank - 1] : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: rankColor.withValues(alpha: 0.15),
                child: Text(
                  agent.agentName.isNotEmpty
                      ? agent.agentName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.agentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Saha Personeli',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: rankColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AgentStat(
              label: 'Toplam Siparis', value: '${agent.totalOrders}'),
          const SizedBox(height: 6),
          _AgentStat(
              label: 'Toplam Gelir',
              value: _currencyFmt.format(agent.totalRevenue)),
          const SizedBox(height: 6),
          _AgentStat(
              label: 'Müşteri Sayisi',
              value: '${agent.customersServed}'),
          const Spacer(),
          // Mini progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Performans',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '%${(barFill * 100).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: rankColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: barFill,
                  backgroundColor: AppColors.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(rankColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentStat extends StatelessWidget {
  final String label;
  final String value;

  const _AgentStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AgentComparisonTable extends StatelessWidget {
  final List<FieldAgentPerformanceData> agents;

  const _AgentComparisonTable({required this.agents});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Karsilastirma Tablosu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: AppColors.adminBackground,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('Personel')),
                Expanded(flex: 2, child: _TableHeader('Siparis')),
                Expanded(flex: 3, child: _TableHeader('Gelir')),
                Expanded(flex: 3, child: _TableHeader('Ort. Siparis')),
                Expanded(flex: 2, child: _TableHeader('Müşteri')),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: agents.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) =>
                _AgentTableRow(agent: agents[i]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AgentTableRow extends StatelessWidget {
  final FieldAgentPerformanceData agent;

  const _AgentTableRow({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              agent.agentName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${agent.totalOrders}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _currencyFmt.format(agent.totalRevenue),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _currencyFmt.format(agent.averageOrderValue),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${agent.customersServed}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TAB 4 — MUSTERI ANALIZI
// ===========================================================================
class _CustomerAnalysisTab extends ConsumerWidget {
  const _CustomerAnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growthAsync = ref.watch(reportCustomerGrowthProvider);

    return growthAsync.when(
      loading: () => const _ReportShimmer(height: 420),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (growth) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CustomerSummaryCards(growth: growth),
          const SizedBox(height: 20),
          _CustomerGrowthChart(growth: growth),
          const SizedBox(height: 20),
          _CustomerGrowthTable(growth: growth),
        ],
      ),
    );
  }
}

class _CustomerSummaryCards extends StatelessWidget {
  final List<CustomerGrowthData> growth;

  const _CustomerSummaryCards({required this.growth});

  @override
  Widget build(BuildContext context) {
    if (growth.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final crossCount =
        width >= _kDesktop ? 4 : (width >= _kTablet ? 2 : 2);

    final last = growth.last;
    final totalNew = growth.fold(0, (s, g) => s + g.newCustomers);

    final cards = [
      _SummaryCardData(
        title: 'Toplam Müşteri',
        value: '${last.totalCustomers}',
        icon: Icons.people_outline,
        iconColor: AppColors.secondary,
        iconBgColor: AppColors.secondary.withValues(alpha: 0.12),
      ),
      _SummaryCardData(
        title: 'Donem Yeni Müşteri',
        value: '$totalNew',
        icon: Icons.person_add_outlined,
        iconColor: AppColors.success,
        iconBgColor: AppColors.success.withValues(alpha: 0.12),
      ),
      _SummaryCardData(
        title: 'Aktif Müşteri',
        value: '${last.activeCustomers}',
        icon: Icons.how_to_reg_outlined,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primary.withValues(alpha: 0.12),
      ),
      _SummaryCardData(
        title: 'Aktivite Orani',
        value:
            '%${last.totalCustomers > 0 ? (last.activeCustomers / last.totalCustomers * 100).toStringAsFixed(0) : 0}',
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.accent,
        iconBgColor: AppColors.accent.withValues(alpha: 0.12),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: width >= _kDesktop ? 1.6 : 1.3,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _SummaryCard(data: cards[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Müşteri Buyume Grafigi — 2 cizgi (yeni + toplam)
// ---------------------------------------------------------------------------
class _CustomerGrowthChart extends StatelessWidget {
  final List<CustomerGrowthData> growth;

  const _CustomerGrowthChart({required this.growth});

  @override
  Widget build(BuildContext context) {
    if (growth.isEmpty) return const SizedBox.shrink();

    final newSpots = growth.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.newCustomers.toDouble());
    }).toList();
    final activeSpots = growth.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), e.value.activeCustomers.toDouble());
    }).toList();

    final maxY = growth
        .map((g) => g.activeCustomers.toDouble())
        .reduce((a, b) => a > b ? a : b);

    final monthFmt = DateFormat('MMM yy', 'tr_TR');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Müşteri Buyume Grafigi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _LegendDot(color: AppColors.primary, label: 'Yeni Müşteri'),
              const SizedBox(width: 12),
              _LegendDot(
                  color: AppColors.accent, label: 'Aktif Müşteri'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.3,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1.0,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= growth.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            monthFmt.format(growth[idx].date),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY > 0 ? maxY / 4 : 1.0,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.secondary,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx < 0 || idx >= growth.length) {
                          return null;
                        }
                        final g = growth[idx];
                        final isNew = spot.barIndex == 0;
                        return LineTooltipItem(
                          isNew
                              ? 'Yeni: ${g.newCustomers}'
                              : 'Aktif: ${g.activeCustomers}',
                          TextStyle(
                            color: isNew
                                ? AppColors.primary
                                : AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Yeni müşteri
                  LineChartBarData(
                    spots: newSpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Aktif müşteri
                  LineChartBarData(
                    spots: activeSpots,
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.12),
                          AppColors.accent.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Müşteri Buyume Tablosu
// ---------------------------------------------------------------------------
class _CustomerGrowthTable extends StatelessWidget {
  final List<CustomerGrowthData> growth;

  const _CustomerGrowthTable({required this.growth});

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMMM yyyy', 'tr_TR');
    final reversed = growth.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Aylik Müşteri Detayi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: AppColors.adminBackground,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('Ay')),
                Expanded(flex: 2, child: _TableHeader('Yeni')),
                Expanded(flex: 2, child: _TableHeader('Aktif')),
                Expanded(flex: 3, child: _TableHeader('Toplam')),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversed.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) {
              final g = reversed[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        monthFmt.format(g.date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '+${g.newCustomers}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${g.activeCustomers}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${g.totalCustomers}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ===========================================================================
// PAYLASILAN YARDIMCI WIDGET'LAR
// ===========================================================================
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReportShimmer extends StatefulWidget {
  final double height;

  const _ReportShimmer({required this.height});

  @override
  State<_ReportShimmer> createState() => _ReportShimmerState();
}

class _ReportShimmerState extends State<_ReportShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              AppColors.shimmerBase,
              AppColors.shimmerHighlight,
              AppColors.shimmerBase,
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Veri yüklenemedi: $message',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                color: AppColors.textHint, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
