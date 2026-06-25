import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum MetricTrend { up, down, neutral }

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final double? changePercent;
  final MetricTrend? trend;
  final Widget? bottomWidget;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.changePercent,
    this.trend,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppShadows.sm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              if (changePercent != null) _TrendBadge(
                percent: changePercent!,
                trend: trend ?? MetricTrend.neutral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
              if (bottomWidget != null) ...[
                const SizedBox(height: 8),
                bottomWidget!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final double percent;
  final MetricTrend trend;

  const _TrendBadge({required this.percent, required this.trend});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData arrowIcon;

    switch (trend) {
      case MetricTrend.up:
        badgeColor = AppColors.success;
        arrowIcon = Icons.arrow_upward_rounded;
      case MetricTrend.down:
        badgeColor = AppColors.error;
        arrowIcon = Icons.arrow_downward_rounded;
      case MetricTrend.neutral:
        badgeColor = AppColors.textSecondary;
        arrowIcon = Icons.remove_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(arrowIcon, size: 12, color: badgeColor),
          const SizedBox(width: 2),
          Text(
            '%${percent.abs().toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Firebase kullanim metrik karti
class FirebaseUsageCard extends StatelessWidget {
  final int currentReads;
  final int dailyLimit;

  const FirebaseUsageCard({
    super.key,
    required this.currentReads,
    required this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (currentReads / dailyLimit).clamp(0.0, 1.0);
    final isWarning = percent > 0.7;
    final isCritical = percent > 0.9;

    final progressColor = isCritical
        ? AppColors.error
        : isWarning
            ? AppColors.warning
            : AppColors.accent;

    return MetricCard(
      title: 'Firebase Kullanim',
      value: '${_formatNumber(currentReads)} okuma',
      subtitle: 'Gunluk limit: ${_formatNumber(dailyLimit)}',
      icon: Icons.cloud_outlined,
      iconColor: progressColor,
      iconBgColor: progressColor.withValues(alpha: 0.12),
      bottomWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(percent * 100).toStringAsFixed(1)}% kullanildi',
            style: TextStyle(
              fontSize: 11,
              color: progressColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }
}
