import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_stats_model.dart';

class WeeklySalesChart extends StatelessWidget {
  final List<DailySalesData> data;

  const WeeklySalesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyChartPlaceholder();

    final maxAmount = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final interval = (maxAmount / 4).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
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
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Haftalik Satis',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              _ChartLegendDot(color: AppColors.primary, label: 'Satis (TL)'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.2,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.secondary,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[group.x];
                      return BarTooltipItem(
                        '${DateFormat('dd MMM', 'tr_TR').format(item.date)}\n',
                        const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                        children: [
                          TextSpan(
                            text:
                                NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0).format(rod.toY),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          TextSpan(
                            text: '\n${item.orderCount} siparis',
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('EEE', 'tr_TR')
                                .format(data[index].date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
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
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          _formatAmount(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
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
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isToday = i == data.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: item.amount,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.45),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxAmount * 1.2,
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'Veri bulunamadi',
          style: TextStyle(color: AppColors.textHint, fontFamily: 'Poppins'),
        ),
      ),
    );
  }
}
