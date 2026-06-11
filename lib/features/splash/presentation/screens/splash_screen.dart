import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nisa_ticaret/core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/asset_paths.dart' show AssetPaths;
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../../auth/presentation/providers/auth_datasource_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _scheduleNavigation();
  }

  /// Semver karşılaştırması: -1 = current < required, 0 = eşit, 1 = current > required
  int _compareVersions(String current, String required) {
    List<int> parse(String v) => v
        .split('.')
        .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final cur = parse(current);
    final req = parse(required);

    for (int i = 0; i < 3; i++) {
      final c = i < cur.length ? cur[i] : 0;
      final r = i < req.length ? req[i] : 0;
      if (c < r) return -1;
      if (c > r) return 1;
    }
    return 0;
  }

  /// Store URL'ini aç — önce market:// dene, açılamazsa web'e düş
  Future<void> _openStore() async {
    const marketUrl = 'market://details?id=com.fuska.nisaticaret';
    const webUrl =
        'https://play.google.com/store/apps/details?id=com.fuska.nisaticaret';

    final marketUri = Uri.parse(marketUrl);
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri);
    } else {
      await launchUrl(
        Uri.parse(webUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// Ekrandan çıkış yapılamayan zorunlu güncelleme dialog'u
  Future<void> _showForceUpdateDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        // Geri tuşunu engelle
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Güncelleme Gerekli',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          content: const Text(
            'Uygulamayı kullanmaya devam etmek için güncelleme yapmanız gerekmektedir.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 46),
              ),
              onPressed: _openStore,
              child: const Text(
                'Güncelle',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // Dialog asla kapatılmaz; uygulama burada bloke kalır.
  }

  Future<void> _scheduleNavigation() async {
    // 1. Force update kontrolü — auth beklemeye gerek yok
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final forceUpdateVersion = AppConfig.instance.forceUpdateVersion;

    if (_compareVersions(currentVersion, forceUpdateVersion) < 0) {
      await _showForceUpdateDialog();
      // Dialog bloke ettiği için buraya ulaşılmaz; güvenlik için çık
      return;
    }

    // 2. Auth durumu çözülene kadar bekle (maks 1 saniye)
    int attempts = 0;
    while (ref.read(authStateProvider).isLoading && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    final user = ref.read(authStateProvider).value;
    final local = ref.read(authLocalDatasourceProvider);

    if (user != null) {
      // Sanctum token + cache mevcut — varlığını /v1/auth/me ile doğrula
      // (401 olursa interceptor TOTP secret ile sessizce yeniler)
      await _verifySession();
      if (!mounted) return;
      final cachedApiUser = local.getUser();
      _navigate(cachedApiUser != null ? UserModel.fromApiUser(cachedApiUser) : user);
    } else {
      // Token/cache yok → cihazda TOTP secret var mı bak (sessiz giriş)
      final hasSecret = await local.hasTotpCredentials;
      if (hasSecret) {
        await _verifySession();
        if (!mounted) return;
        final cachedApiUser = local.getUser();
        if (cachedApiUser != null) {
          _navigate(UserModel.fromApiUser(cachedApiUser));
          return;
        }
      }

      // 3. Onboarding kontrolü — sadece giriş yapmamış kullanıcılar için
      final prefs = await SharedPreferences.getInstance();
      final onboardingSeen =
          prefs.getBool(AppConstants.keyOnboardingSeen) ?? false;

      // Splash animasyonunu göster
      await Future.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;

      if (!onboardingSeen) {
        context.go(AppRoutes.onboarding);
      } else {
        _navigate(null);
      }
    }
  }

  /// Sanctum token'ın geçerliliğini /v1/auth/me ile doğrular.
  /// 401 durumunda AuthInterceptor cihazdaki TOTP secret ile sessizce
  /// yeni bir token alır ve isteği tekrar dener.
  Future<void> _verifySession() async {
    try {
      final local = ref.read(authLocalDatasourceProvider);
      final remote = ref.read(authRemoteDatasourceProvider);
      final freshUser = await remote.getCurrentUser();
      await local.saveUser(freshUser);
      ref.invalidate(authStateProvider);
    } catch (e) {
      debugPrint('SplashScreen._verifySession hata: $e');
    }
  }

  void _navigate(dynamic user) {
    if (!mounted) return;
    if (user == null) {
      context.go(AppRoutes.home);
    } else {
      context.go(_roleHome(user.role));
    }
  }

  String _roleHome(UserRole role) => switch (role) {
        UserRole.admin => AppRoutes.adminHome,
        UserRole.fieldAgent => AppRoutes.fieldAgentHome,
        UserRole.delivery => AppRoutes.deliveryHome,
        UserRole.customer => AppRoutes.home,
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Arka plan görseli
          Positioned.fill(
            child: Image.asset(
              AssetPaths.splashWaveBg,
              fit: BoxFit.cover,
            ),
          ),
          // Alt: loading bar
          Positioned(
            bottom: 48,
            left: 60,
            right: 60,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 3,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
