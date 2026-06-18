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

  // 2+3. Locale ve Remote Config bağımsız → paralel
  await Future.wait([
    initializeDateFormatting('tr_TR'),
    appConfig.init(),
  ]);

  // 4. Hive.initFlutter() — tek sıralı çalışması gereken adım
  await cacheService.init();

  // 5+6. CacheManager (Hive box açma) ve FCM bağımsız → paralel
  final cacheManager = CacheManager();
  await Future.wait([
    cacheManager.init(),
    notificationService.initialize(),
  ]);

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

    // Bildirime tıklanınca ilgili route'a yönlendir
    ref.listen(notificationTapProvider, (_, next) {
      next.whenData((route) => router.push(route));
    });

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
