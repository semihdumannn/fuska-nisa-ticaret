import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/services/whatsapp_service.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
// ---------------------------------------------------------------------------
// _packageInfoProvider — uygulama versiyonunu bir kez cekip cache'ler
// ---------------------------------------------------------------------------
final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

// ---------------------------------------------------------------------------
// _MenuItem — menü kalemini tutan basit veri sinifi
// ---------------------------------------------------------------------------
class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

// ---------------------------------------------------------------------------
// ProfileScreen
// ---------------------------------------------------------------------------
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Bir hata oluştu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      data: (user) => _ProfileContent(user: user),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProfileContent — kullanici null olmadigi garantiyle render edilir
// ---------------------------------------------------------------------------
class _ProfileContent extends ConsumerWidget {
  final UserModel? user;
  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Giriş yapılmamış → login ekranı göster
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('Profilim',
              style: Theme.of(context).textTheme.headlineSmall),
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hesabınıza giriş yapın',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Profilinizi görüntülemek ve siparişlerinizi takip etmek için giriş yapın.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.phoneAuth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Giriş Yap',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final packageInfoAsync = ref.watch(_packageInfoProvider);
    final String appVersion = packageInfoAsync.when(
      data: (info) => '${info.version} (${info.buildNumber})',
      loading: () => '...',
      error: (_, __) => '-',
    );
    final menuItems = _buildMenuItems(context, user!, appVersion);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Profilim',
            style: Theme.of(context).textTheme.headlineSmall),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeaderCard(user: user),
          const SizedBox(height: 20),
          if (menuItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MenuSection(items: menuItems),
            ),
            const SizedBox(height: 24),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SignOutButton(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<_MenuItem> _buildMenuItems(
    BuildContext context,
    UserModel user,
    String appVersion,
  ) {
    switch (user.role) {
      case UserRole.customer:
        return _customerMenuItems(context, appVersion);
      case UserRole.admin:
        return _adminMenuItems(context, appVersion);
      case UserRole.fieldAgent:
        return _fieldAgentMenuItems(context, appVersion);
      case UserRole.delivery:
        return _deliveryMenuItems(context, appVersion);
    }
  }

  List<_MenuItem> _customerMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.edit_outlined,
        title: 'Bilgilerimi Düzenle',
        onTap: () => context.push(AppRoutes.profileEdit),
      ),
      _MenuItem(
        icon: Icons.location_on_outlined,
        title: 'Adreslerim',
        onTap: () => context.push(AppRoutes.addressSelection),
      ),
      _MenuItem(
        icon: Icons.shopping_bag_outlined,
        title: 'Siparişlerim',
        onTap: () => context.push(AppRoutes.orders),
      ),
      _MenuItem(
        icon: Icons.favorite_border,
        title: 'Favorilerim',
        onTap: () => context.push(AppRoutes.favorites),
      ),
      _MenuItem(
        icon: Icons.autorenew,
        title: 'Aboneliğim',
        onTap: () => context.push(AppRoutes.subscription),
      ),
      _MenuItem(
        icon: Icons.local_offer_outlined,
        title: 'Kampanyalar',
        onTap: () => context.push(AppRoutes.campaigns),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.support_agent_outlined,
        title: 'WhatsApp Destek',
        onTap: () => whatsappService.contactSupport(
          message: 'Merhaba! Uygulama hakkında yardım almak istiyorum.',
        ),
      ),
      _MenuItem(
        icon: Icons.help_outline,
        title: 'Yardım',
        onTap: () {},
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () => _showAboutDialog(context, appVersion),
      ),
    ];
  }

  void _showAboutDialog(BuildContext context, String version) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/app_icon.png', width: 40, height: 40, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            const Text('Nisa Ticaret', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutRow(label: 'Sürüm', value: version),
            _AboutRow(label: 'Geliştirici', value: 'Fuska A.Ş.'),
            _AboutRow(label: 'İletişim', value: 'info@fuska.com.tr'),
            const SizedBox(height: 8),
            const Text(
              'Fuska Nisa Ticaret uygulaması; su ve meşrubat siparişleri için geliştirilmiştir.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins', height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<_MenuItem> _adminMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.dashboard_outlined,
        title: 'Yönetim Paneli',
        onTap: () => context.go(AppRoutes.adminHome),
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Sipariş Yönetimi',
        onTap: () => context.push(AppRoutes.orderManagement),
      ),
      _MenuItem(
        icon: Icons.group_outlined,
        title: 'Kullanıcılar',
        onTap: () => context.push(AppRoutes.adminUsers),
      ),
      _MenuItem(
        icon: Icons.bar_chart_outlined,
        title: 'Raporlar',
        onTap: () => context.push(AppRoutes.adminReports),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () => _showAboutDialog(context, appVersion),
      ),
    ];
  }

  List<_MenuItem> _fieldAgentMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.home_outlined,
        title: 'Saha Terminali',
        onTap: () => context.go(AppRoutes.fieldAgentHome),
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Siparişlerim',
        onTap: () => context.push(AppRoutes.orders),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () => _showAboutDialog(context, appVersion),
      ),
    ];
  }

  List<_MenuItem> _deliveryMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.local_shipping_outlined,
        title: 'Teslimat Paneli',
        onTap: () => context.go(AppRoutes.deliveryHome),
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Siparişlerim',
        onTap: () => context.push(AppRoutes.orders),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () => _showAboutDialog(context, appVersion),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// _HeaderCard — kullanici profil karti
// ---------------------------------------------------------------------------
class _HeaderCard extends StatelessWidget {
  final UserModel? user;
  const _HeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(user?.name);
    final String displayName =
        (user?.name.isNotEmpty == true) ? user!.name : 'Kullanici';
    final String phone = user?.phone ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _Avatar(initials: initials),
          const SizedBox(height: 12),
          Tooltip(
            message: displayName,
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          if (user != null) _RoleBadge(role: user!.role),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// _Avatar
// ---------------------------------------------------------------------------
class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      alignment: Alignment.center,
      child: initials == '?'
          ? const Icon(Icons.person, color: AppColors.textWhite, size: 32)
          : Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RoleBadge — rol bazli renk ve etiket
// ---------------------------------------------------------------------------
class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final Color bg = _badgeColor.withValues(alpha: 0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _badgeLabel,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _badgeColor,
        ),
      ),
    );
  }

  String get _badgeLabel {
    switch (role) {
      case UserRole.customer:
        return 'Müşteri';
      case UserRole.admin:
        return 'Yönetici';
      case UserRole.fieldAgent:
        return 'Saha Ekibi';
      case UserRole.delivery:
        return 'Teslimat';
    }
  }

  Color get _badgeColor {
    switch (role) {
      case UserRole.customer:
        return AppColors.accent;
      case UserRole.admin:
        return AppColors.secondary;
      case UserRole.fieldAgent:
        return AppColors.primary;
      case UserRole.delivery:
        return AppColors.success;
    }
  }
}

// ---------------------------------------------------------------------------
// _MenuSection — menü kalemlerinin listesi (her item ayrı kart)
// ---------------------------------------------------------------------------
class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _MenuCard(item: item)).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// _MenuCard — tekil menü kalemi kartı
// ---------------------------------------------------------------------------
class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppShadows.sm],
      ),
      child: ListTile(
        onTap: item.onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: AppColors.waterBlue, size: 20),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textHint,
          size: 20,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AboutRow — Hakkında dialog'u için etiket/değer satırı
// ---------------------------------------------------------------------------
class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SignOutButton — cikis butonu + onay dialog'u
// ---------------------------------------------------------------------------
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, ref),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(46),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Çıkış Yap'),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // Başlık
              const Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Açıklama
              const Text(
                'Çıkış yapmak istediğinizden emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.home);
    }
  }
}
