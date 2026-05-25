import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/connectivity_banner.dart';
import 'core/config/app_config.dart';
import 'core/services/cache_service.dart';
import 'core/services/notification_service.dart';
import 'core/cache/cache_manager.dart';
import 'core/providers/core_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Locale data (intl - DateFormat icin)
  await initializeDateFormatting('tr_TR');

  // 3. App Config (Remote Config)
  await appConfig.init();

  // 4. Cache Service (Local - Firestore cache icin)
  await cacheService.init();

  // 5. Hive + CacheManager (API token ve API data cache icin)
  // Not: cacheService.init() zaten Hive.initFlutter() cagiriyor,
  // CacheManager yalnizca box'larini aciyor.
  final cacheManager = CacheManager();
  await cacheManager.init();

  // 6. FCM — izin iste, token al, handler'lari baslat
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        cacheManagerProvider.overrideWithValue(cacheManager),
      ],
      child: const NisaTicaretApp(),
    ),
  );
}

class NisaTicaretApp extends ConsumerWidget {
  const NisaTicaretApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Nisa Ticaret',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) =>
          ConnectivityBanner(child: child ?? const SizedBox()),
    );
  }
}
