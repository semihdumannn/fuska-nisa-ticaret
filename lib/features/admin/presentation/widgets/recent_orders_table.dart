import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_orders_provider.dart'
    hide ordersPageProvider, totalOrderPagesProvider;

class RecentOrdersTable extends ConsumerWidget {
  const RecentOrdersTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(filteredRecentOrdersProvider);
    final currentPage = ref.watch(ordersPageProvider);
    final totalPages = ref.watch(totalOrderPagesProvider);
    final statusFilter = ref.watch(selectedOrderStatusFilterProvider);

    return Container(
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
          _TableHeader(
            statusFilter: statusFilter,
            onStatusChanged: (val) {
              ref.read(selectedOrderStatusFilterProvider.notifier).setFilter(val);
              ref.read(ordersPageProvider.notifier).reset();
            },
          ),
          const Divider(height: 1),
          if (orders.isEmpty)
            const _EmptyTablePlaceholder()
          else
            _OrderTableContent(orders: orders),
          const Divider(height: 1),
          _TablePagination(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: (page) {
              ref.read(ordersPageProvider.notifier).setPage(page);
            },
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String? statusFilter;
  final ValueChanged<String?> onStatusChanged;

  const _TableHeader({
    required this.statusFilter,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined,
              color: AppColors.secondary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Son Siparisler',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          _StatusFilterDropdown(
            value: statusFilter,
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _StatusFilterDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _StatusFilterDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text(
            'Tum Durumlar',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tum Durumlar'),
            ),
            ...OrderStatus.values.map((s) => DropdownMenuItem<String?>(
                  value: s.value,
                  child: Text(s.displayName),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _OrderTableContent extends StatelessWidget {
  final List<RecentOrderSummary> orders;

  const _OrderTableContent({required this.orders});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 700;

    return Column(
      children: [
        _ColumnHeaders(isWide: isWide),
        const Divider(height: 1, color: AppColors.divider),
        ...orders.map((order) => _OrderRow(order: order, isWide: isWide)),
      ],
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  final bool isWide;

  const _ColumnHeaders({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.adminBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _HeaderCell('#No', flex: 2),
          _HeaderCell('Müşteri', flex: 3),
          if (isWide) _HeaderCell('Tutar', flex: 2),
          _HeaderCell('Durum', flex: 3),
          if (isWide) _HeaderCell('Tarih', flex: 3),
          _HeaderCell('Islemler', flex: 2, isRight: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isRight;

  const _HeaderCell(this.text, {required this.flex, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: isRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _OrderRow extends ConsumerWidget {
  final RecentOrderSummary order;
  final bool isWide;

  const _OrderRow({required this.order, required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              order.orderNo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              order.customerName,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isWide)
            Expanded(
              flex: 2,
              child: Text(
                NumberFormat.currency(
                  locale: 'tr_TR',
                  symbol: '₺',
                  decimalDigits: 2,
                ).format(order.total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: OrderStatusBadge(status: order.status),
          ),
          if (isWide)
            Expanded(
              flex: 3,
              child: Text(
                DateFormat('dd MMM, HH:mm', 'tr_TR').format(order.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: Icons.visibility_outlined,
                  tooltip: 'Görüntüle',
                  onTap: () => context.push(
                    AppRoutes.adminOrderDetail.replaceFirst(':id', order.id),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<AdminOrderStatus>(
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textSecondary),
                  tooltip: 'Durum Güncelle',
                  itemBuilder: (_) => AdminOrderStatus.values
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Text(s.displayName,
                                style: const TextStyle(
                                    fontSize: 13, fontFamily: 'Poppins')),
                          ))
                      .toList(),
                  onSelected: (newStatus) async {
                    await ref
                        .read(adminOrdersProvider.notifier)
                        .updateStatus(order.id, newStatus);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${order.orderNo} → ${newStatus.displayName}'),
                          backgroundColor: newStatus.color,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 15, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyTablePlaceholder extends StatelessWidget {
  const _EmptyTablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Siparis bulunamadı',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _TablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _TablePagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Sayfa ${currentPage + 1} / $totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 16),
          _PageButton(
            icon: Icons.chevron_left,
            isEnabled: currentPage > 0,
            onTap: () => onPageChanged(currentPage - 1),
            tooltip: 'Onceki',
          ),
          const SizedBox(width: 4),
          ...List.generate(totalPages, (i) {
            if (totalPages <= 5 || (i == 0 || i == totalPages - 1 || (i - currentPage).abs() <= 1)) {
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _PageNumberButton(
                  page: i,
                  isActive: i == currentPage,
                  onTap: () => onPageChanged(i),
                ),
              );
            }
            if ((i - currentPage).abs() == 2) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.chevron_right,
            isEnabled: currentPage < totalPages - 1,
            onTap: () => onPageChanged(currentPage + 1),
            tooltip: 'Sonraki',
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;
  final String tooltip;

  const _PageButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.surface : AppColors.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isEnabled ? AppColors.textSecondary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageNumberButton({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.textWhite : AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

// Siparis durum badge'i — diger ekranlarda da kullanilabilir
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool compact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color get _color {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.onTheWay:
        return AppColors.statusOnTheWay;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: _color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
