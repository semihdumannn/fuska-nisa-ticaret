import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';

enum _SubscriptionPlan { weekly, biweekly, monthly }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  _SubscriptionPlan _selectedPlan = _SubscriptionPlan.weekly;
  final bool _hasActiveSubscription = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Aboneligim',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.navBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _hasActiveSubscription
          ? _buildActiveSubscription()
          : _buildNoSubscription(),
    );
  }

  Widget _buildNoSubscription() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bos state
          Center(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.pinkLight,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.repeat,
                    size: 40,
                    color: AppColors.primary,
                  ),
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
                  'Duzenli siparis vererek indirim kazan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Plan baslik
          Text(
            'Abonelik Plani Sec',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Haftalik
          _PlanCard(
            plan: _SubscriptionPlan.weekly,
            selectedPlan: _selectedPlan,
            planName: 'Haftalik',
            discount: 10,
            frequency: 'Her hafta',
            onTap: () => setState(() => _selectedPlan = _SubscriptionPlan.weekly),
          ),

          // 2 Haftada bir
          _PlanCard(
            plan: _SubscriptionPlan.biweekly,
            selectedPlan: _selectedPlan,
            planName: '2 Haftada bir',
            discount: 8,
            frequency: '2 haftada bir',
            onTap: () => setState(() => _selectedPlan = _SubscriptionPlan.biweekly),
          ),

          // Aylik
          _PlanCard(
            plan: _SubscriptionPlan.monthly,
            selectedPlan: _selectedPlan,
            planName: 'Aylik',
            discount: 5,
            frequency: 'Her ay',
            onTap: () => setState(() => _selectedPlan = _SubscriptionPlan.monthly),
          ),

          const SizedBox(height: 32),

          // CTA butonu (gradient)
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(46),
              boxShadow: const [AppShadows.primary],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(46),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  child: Text(
                    'Abonelik Olustur',
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

  Widget _buildActiveSubscription() {
    return Center(
      child: Text(
        'Aktif abonelik detaylari',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _SubscriptionPlan plan;
  final _SubscriptionPlan selectedPlan;
  final String planName;
  final int discount;
  final String frequency;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selectedPlan,
    required this.planName,
    required this.discount,
    required this.frequency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = plan == selectedPlan;
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
        child: Row(
          children: [
            // Manuel radio circle
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
                  ? const Center(
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
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
              ],
            ),
            const Spacer(),
            Text(
              frequency,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
