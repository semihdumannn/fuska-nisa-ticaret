import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, [Object? error, StackTrace? st]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
      if (error != null) debugPrint('   Error: $error');
      if (st != null) debugPrint('   Stack: $st');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
      if (error != null) debugPrint('   Error: $error');
    }
  }

  static void error(String message, [Object? error, StackTrace? st]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('   Error: $error');
      if (st != null) debugPrint('   Stack: $st');
    }
    // Production'da: Firebase Crashlytics'e gonder
  }

  static void network(String method, String url, int? statusCode) {
    if (kDebugMode) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      debugPrint('[NET] $method $url$status');
    }
  }
}
