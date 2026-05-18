import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/services/cache_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Locale data (intl - DateFormat için)
  await initializeDateFormatting('tr_TR');

  // 3. App Config (Remote Config)
  await appConfig.init();

  // 4. Cache Service (Local)
  await cacheService.init();

  // 5. FCM — izin iste, token al, handler'ları başlat
  // Background handler Firebase.initializeApp'tan sonra kaydedilmeli.
  await notificationService.initialize();

  runApp(
    const ProviderScope(
      child: NisaTicaretApp(),
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
    );
  }
}
