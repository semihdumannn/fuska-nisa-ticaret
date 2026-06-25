import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_stats_model.dart';

class TopProductsList extends StatelessWidget {
  final List<TopProductData> products;

  const TopProductsList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'En Cok Satanlar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Bu haftanin en çok satan ürünleri',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          ...products.map((p) => _ProductRow(product: p)),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final TopProductData product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _RankBadge(rank: product.rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.soldCount} adet',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(
                  locale: 'tr_TR',
                  symbol: '₺',
                  decimalDigits: 0,
                ).format(product.totalRevenue),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'toplam',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  Color get _bgColor {
    switch (rank) {
      case 1:
        return AppColors.medalGold.withValues(alpha: 0.15);
      case 2:
        return AppColors.medalSilver.withValues(alpha: 0.20);
      case 3:
        return AppColors.medalBronze.withValues(alpha: 0.15);
      default:
        return AppColors.border;
    }
  }

  Color get _textColor {
    switch (rank) {
      case 1:
        return AppColors.medalGoldDark;
      case 2:
        return AppColors.medalSilverDark;
      case 3:
        return AppColors.medalBronzeDark;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
      ),
    );
  }
}
