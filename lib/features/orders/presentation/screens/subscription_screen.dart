import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/models/subscription_model.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: const Text('Aboneliğim'),
      ),
      body: subsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _EmptyState(
          icon: Icons.error_outline,
          title: 'Yüklenemedi',
          subtitle: 'Lütfen tekrar deneyin',
          onRetry: () => ref.invalidate(subscriptionsProvider),
        ),
        data: (subs) {
          if (subs.isEmpty) return const _NoSubscriptionView();
          return _SubscriptionList(subscriptions: subs);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aktif abonelik listesi
// ---------------------------------------------------------------------------
class _SubscriptionList extends StatelessWidget {
  final List<SubscriptionModel> subscriptions;
  const _SubscriptionList({required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subscriptions.length,
      itemBuilder: (_, i) => _SubscriptionCard(sub: subscriptions[i]),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final SubscriptionModel sub;
  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMMM yyyy', 'tr_TR');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppShadows.sm],
      ),
      child: Column(
        children: [
          // Header — gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.productName ?? 'Ürün',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (sub.variantName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sub.variantName!,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
                _StatusChip(status: sub.status),
              ],
            ),
          ),
          // Detaylar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.repeat,
                  label: 'Plan',
                  value: '${sub.planLabel} — %${sub.discountPercent} indirim',
                ),
                const SizedBox(height: 10),
                if (sub.nextDeliveryDate != null)
                  _InfoRow(
                    icon: Icons.local_shipping_outlined,
                    label: 'Sonraki Teslimat',
                    value: dateFormat.format(sub.nextDeliveryDate!),
                  ),
                if (sub.startDate != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Başlangıç',
                    value: dateFormat.format(sub.startDate!),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: sub.isActive
                            ? () => _updateStatus(context, ref, 'paused')
                            : () => _updateStatus(context, ref, 'active'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(sub.isActive ? 'Duraklat' : 'Devam Et'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancel(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('İptal Et'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(subscriptionDatasourceProvider).updateSubscription(sub.id, status: newStatus);
      ref.invalidate(subscriptionsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, size: 28, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(
                'Aboneliği İptal Et',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu abonelik kalıcı olarak iptal edilecek.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    child: const Text('İptal Et'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (ok == true && context.mounted) {
      try {
        await ref.read(subscriptionDatasourceProvider).cancelSubscription(sub.id);
        ref.invalidate(subscriptionsProvider);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İptal başarısız'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (status) {
      'active' => ('Aktif', const Color(0xFF43A047)),
      'paused' => ('Duraklatıldı', const Color(0xFFE73A99)),
      _ => ('İptal', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Text(
        '$label: ',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
      ),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Abonelik yok durumu
// ---------------------------------------------------------------------------
class _NoSubscriptionView extends StatefulWidget {
  const _NoSubscriptionView();
  @override
  State<_NoSubscriptionView> createState() => _NoSubscriptionViewState();
}

class _NoSubscriptionViewState extends State<_NoSubscriptionView> {
  _Plan _selected = _Plan.weekly;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppColors.pinkLight, shape: BoxShape.circle),
                child: const Icon(Icons.repeat, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Aktif abonelik yok',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Düzenli sipariş vererek indirim kazan',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
            ]),
          ),
          Text(
            'Abonelik Planı Seç',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._Plan.values.map((plan) => _PlanCard(
                plan: plan,
                selectedPlan: _selected,
                onTap: () => setState(() => _selected = plan),
              )),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(46),
              boxShadow: const [AppShadows.primary],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abonelik oluşturmak için ürün detayını ziyaret edin'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(46),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  child: Text(
                    'Abonelik Oluştur',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

enum _Plan { weekly, biweekly, monthly }

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final _Plan selectedPlan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.selectedPlan, required this.onTap});

  static const _info = {
    _Plan.weekly: ('Haftalık', 10, 'Her hafta'),
    _Plan.biweekly: ('2 Haftada Bir', 8, '2 haftada bir'),
    _Plan.monthly: ('Aylık', 5, 'Her ay'),
  };

  @override
  Widget build(BuildContext context) {
    final isSelected = plan == selectedPlan;
    final (name, discount, freq) = _info[plan]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pinkLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? const [AppShadows.sm] : null,
        ),
        child: Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 5 : 1.5,
              ),
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
            child: isSelected
                ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Colors.white))
                : null,
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '%$discount indirim',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ]),
          const Spacer(),
          Text(
            freq,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Genel hata durumu
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 48, color: AppColors.textHint),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
      ]),
    );
  }
}
