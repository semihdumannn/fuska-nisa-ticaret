import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/field_agent/data/repositories/customer_repository.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final customerOrdersProvider =
    FutureProvider.family<List<OrderModel>, String>((ref, uid) {
  return ref.watch(orderRepositoryProvider).getUserOrders(uid);
});

final customerAddressesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
  // CustomerRepository.getCustomerAddresses → users/{uid}/addresses subcollection
  return ref.watch(customerRepositoryProvider).getCustomerAddresses(uid);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CustomerDetailScreen extends ConsumerWidget {
  final UserModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(customer.name),
        iconTheme: const IconThemeData(color: AppColors.secondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.success),
            onPressed: null,
            tooltip: customer.phone,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContactCard(customer: customer),
          const SizedBox(height: 16),
          _AddressesSection(uid: customer.uid),
          const SizedBox(height: 16),
          _OrderHistorySection(uid: customer.uid),
          const SizedBox(height: 88),
        ],
      ),
      bottomNavigationBar: _QuickOrderBar(customer: customer),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Iletisim Bilgileri Card
// ---------------------------------------------------------------------------

class _ContactCard extends StatelessWidget {
  final UserModel customer;

  const _ContactCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(customer.name);
    final joinDate = DateFormat('dd.MM.yyyy').format(customer.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Musteri',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Uye: $joinDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// 2. Adresler Bolumu
// ---------------------------------------------------------------------------

class _AddressesSection extends ConsumerWidget {
  final String uid;

  const _AddressesSection({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(customerAddressesProvider(uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        addressesAsync.when(
          loading: () => const _ShimmerBlock(height: 72),
          error: (e, _) => const _InlineError(message: 'Adresler yuklenemedi'),
          data: (addresses) {
            if (addresses.isEmpty) {
              return const _InlineEmpty(message: 'Kayitli adres yok');
            }
            return Column(
              children: addresses
                  .map((addr) => _AddressCard(address: addr))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;

  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    final fullAddress = address['fullAddress'] as String? ?? '';
    final district = address['district'] as String? ?? '';
    final city = address['city'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (district.isNotEmpty || city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [district, city]
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Siparis Gecmisi
// ---------------------------------------------------------------------------

class _OrderHistorySection extends ConsumerWidget {
  final String uid;

  const _OrderHistorySection({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider(uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Siparis Gecmisi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ordersAsync.when(
          loading: () => Column(
            children: List.generate(3, (_) => const _ShimmerBlock(height: 56)),
          ),
          error: (e, _) =>
              const _InlineError(message: 'Siparisler yuklenemedi'),
          data: (orders) {
            if (orders.isEmpty) {
              return const _InlineEmpty(message: 'Siparis gecmisi yok');
            }
            final displayed = orders.take(5).toList();
            return Column(
              children: [
                ...displayed.map((o) => _OrderRow(order: o)),
                if (orders.length > 5)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Tumunu Gor'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;

  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yy').format(order.createdAt);
    final statusColor = _statusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(
              '#${order.orderNo}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${order.total.toStringAsFixed(2)} TL',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.status.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.onTheWay:
        return AppColors.statusOnTheWay;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      case OrderStatus.pending:
        return AppColors.statusPending;
    }
  }
}

// ---------------------------------------------------------------------------
// 4. Bottom Bar
// ---------------------------------------------------------------------------

class _QuickOrderBar extends StatelessWidget {
  final UserModel customer;

  const _QuickOrderBar({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.quickOrder, extra: customer),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Hizli Siparis Olustur'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper widgets
// ---------------------------------------------------------------------------

class _ShimmerBlock extends StatelessWidget {
  final double height;

  const _ShimmerBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String message;

  const _InlineEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
