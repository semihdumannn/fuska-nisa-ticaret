import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/metric_card.dart';
import '../widgets/recent_orders_table.dart';
import '../widgets/top_products_list.dart';
import '../widgets/weekly_sales_chart.dart';

// Breakpoint sabitleri
const double _kDesktopBreakpoint = 1024.0;
const double _kTabletBreakpoint = 700.0;

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    final isTablet = width >= _kTabletBreakpoint && !isDesktop;

    if (isDesktop) {
      return const _DesktopLayout();
    }
    return _MobileTabletLayout(isTablet: isTablet);
  }
}

// Desktop layout: sabit sidebar + scrollable content
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: Row(
        children: [
          AdminSidebar(),
          Expanded(
            child: _DashboardContent(),
          ),
        ],
      ),
    );
  }
}

// Mobil/Tablet layout: drawer sidebar
class _MobileTabletLayout extends StatelessWidget {
  final bool isTablet;

  const _MobileTabletLayout({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      drawer: const AdminDrawerWrapper(),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Yönetim Paneli',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined,
                color: AppColors.textWhite),
            tooltip: 'Müşteri Görünümü',
            onPressed: () => context.go(AppRoutes.home),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textWhite),
            onPressed: () => context.push(AppRoutes.notifications),
            tooltip: 'Bildirimler',
          ),
        ],
      ),
      body: const _DashboardContent(),
    );
  }
}

// Ortak dashboard içerik alanı
class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const _DashboardShimmer(),
      error: (e, st) => _DashboardError(error: e),
      data: (stats) => _DashboardScrollView(stats: stats),
    );
  }
}

class _DashboardScrollView extends StatelessWidget {
  final dynamic stats;

  const _DashboardScrollView({required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    final isTablet = width >= _kTabletBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardHeader(isDesktop: isDesktop),
          const SizedBox(height: 24),
          _MetricsGrid(stats: stats, isTablet: isTablet, isDesktop: isDesktop),
          const SizedBox(height: 24),
          _ChartsRow(stats: stats, isTablet: isTablet),
          const SizedBox(height: 24),
          _BottomSection(stats: stats, isTablet: isTablet),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// Header: başlık + tarih seçici + export
class _DashboardHeader extends ConsumerWidget {
  final bool isDesktop;

  const _DashboardHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(selectedDateRangeProvider);
    final now = DateTime.now();
    final todayStr = DateFormat('dd MMMM yyyy', 'tr_TR').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yönetim Paneli',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                todayStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          children: [
            _DateRangeButton(
              startDate: dateRange.start,
              endDate: dateRange.end,
              onRangeSelected: (start, end) {
                ref
                    .read(selectedDateRangeProvider.notifier)
                    .setRange(start, end);
              },
            ),
            _ExportButton(isDesktop: isDesktop),
          ],
        ),
      ],
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime start, DateTime end) onRangeSelected;

  const _DateRangeButton({
    required this.startDate,
    required this.endDate,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        '${DateFormat('dd MMM', 'tr_TR').format(startDate)} - ${DateFormat('dd MMM', 'tr_TR').format(endDate)}';

    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          initialDateRange: DateTimeRange(start: startDate, end: endDate),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onRangeSelected(picked.start, picked.end);
        }
      },
      icon: const Icon(Icons.date_range_outlined, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool isDesktop;

  const _ExportButton({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push(AppRoutes.adminReports),
      icon: const Icon(Icons.download_outlined, size: 16),
      label: Text(isDesktop ? 'Disa Aktar' : ''),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textWhite,
        minimumSize: Size(isDesktop ? 130 : 44, 40),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 10,
          vertical: 0,
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// 4-kolon metrik grid
class _MetricsGrid extends StatelessWidget {
  final dynamic stats;
  final bool isTablet;
  final bool isDesktop;

  const _MetricsGrid({
    required this.stats,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.1 : 1.6),
      children: [
        MetricCard(
          title: 'Günlük Satış',
          value: NumberFormat.currency(
            locale: 'tr_TR',
            symbol: '₺',
            decimalDigits: 0,
          ).format(stats.dailySales),
          subtitle: 'Bugün toplam ciro',
          icon: Icons.attach_money_rounded,
          iconColor: AppColors.success,
          iconBgColor: AppColors.success.withValues(alpha: 0.12),
          changePercent: stats.dailySalesChangePercent,
          trend: stats.dailySalesChangePercent >= 0
              ? MetricTrend.up
              : MetricTrend.down,
        ),
        MetricCard(
          title: 'Toplam Sipariş',
          value: '${stats.totalOrders} adet',
          subtitle: 'Bugünün siparişleri',
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primary.withValues(alpha: 0.12),
        ),
        MetricCard(
          title: 'Aktif Müşteriler',
          value: '${stats.activeCustomers}',
          subtitle: 'Son 30 günde aktif',
          icon: Icons.people_outline_rounded,
          iconColor: AppColors.secondary,
          iconBgColor: AppColors.secondary.withValues(alpha: 0.10),
        ),
        FirebaseUsageCard(
          currentReads: stats.firebaseUsage.dailyReads,
          dailyLimit: stats.firebaseUsage.dailyLimit,
        ),
      ],
    );
  }
}

// Yan yana chart satiri
class _ChartsRow extends StatelessWidget {
  final dynamic stats;
  final bool isTablet;

  const _ChartsRow({required this.stats, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    if (isTablet) {
      // Tablet ve desktop: yan yana
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: WeeklySalesChart(data: stats.weeklySales),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: CategoryPieChart(data: stats.categorySales),
          ),
        ],
      );
    }
    // Mobil: alt alta
    return Column(
      children: [
        WeeklySalesChart(data: stats.weeklySales),
        const SizedBox(height: 16),
        CategoryPieChart(data: stats.categorySales),
      ],
    );
  }
}

// Alt section: top products + siparis tablosu
class _BottomSection extends StatelessWidget {
  final dynamic stats;
  final bool isTablet;

  const _BottomSection({required this.stats, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: TopProductsList(products: stats.topProducts),
          ),
          const SizedBox(width: 16),
          const Expanded(child: RecentOrdersTable()),
        ],
      );
    }

    return Column(
      children: [
        TopProductsList(products: stats.topProducts),
        const SizedBox(height: 16),
        const RecentOrdersTable(),
      ],
    );
  }
}

// Shimmer yukleme durumu
class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    final isTablet = width >= _kTabletBreakpoint && !isDesktop;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
    final childAspectRatio = isDesktop ? 1.5 : (isTablet ? 1.1 : 1.6);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 200, height: 28),
          const SizedBox(height: 6),
          _ShimmerBox(width: 140, height: 16),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
            children: List.generate(4, (_) => _ShimmerCard()),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(flex: 6, child: _ShimmerBox(width: double.infinity, height: 260)),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: _ShimmerBox(width: double.infinity, height: 260)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShimmerBox(width: 44, height: 44, radius: 12),
          const Spacer(),
          _ShimmerBox(width: 80, height: 20),
          const SizedBox(height: 6),
          _ShimmerBox(width: 120, height: 14),
        ],
      ),
    );
  }
}

// Hata durumu
class _DashboardError extends StatelessWidget {
  final Object error;

  const _DashboardError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Veriler yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
