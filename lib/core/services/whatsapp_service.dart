import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

/// WhatsApp URL launcher — müşteri destek ve saha personeli kullanımı.
///
/// Otomatik sipariş bildirimleri Cloud Functions + Twilio üzerinden gider.
/// Bu servis sadece kullanıcının manuel olarak WhatsApp açması içindir.
class WhatsappService {
  static final WhatsappService _instance = WhatsappService._();
  factory WhatsappService() => _instance;
  WhatsappService._();

  /// Nisa Ticaret destek hattına WhatsApp açar.
  ///
  /// [message]: Önceden doldurulmuş mesaj (opsiyonel).
  Future<void> contactSupport({String? message}) async {
    final phone = _normalize(appConfig.whatsappNumber);
    await _launch(phone, message: message);
  }

  /// Belirli bir telefon numarasına WhatsApp açar.
  ///
  /// [phone]: +90 veya 0 ile başlayan Türk numarası.
  /// [message]: Önceden doldurulmuş mesaj (opsiyonel).
  Future<void> openChat({required String phone, String? message}) async {
    final normalized = _normalize(phone);
    await _launch(normalized, message: message);
  }

  /// Sipariş hakkında destek mesajı açar.
  Future<void> supportForOrder({
    required String orderNo,
    String? extraMessage,
  }) async {
    final base = 'Merhaba! $orderNo numaralı sipariş hakkında soru sormak istiyorum.';
    final message = extraMessage != null ? '$base\n$extraMessage' : base;
    await contactSupport(message: message);
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  String _normalize(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90')) return digits;
    if (digits.startsWith('0')) return '9$digits';
    return '90$digits';
  }

  Future<void> _launch(String normalizedPhone, {String? message}) async {
    final encoded = message != null ? Uri.encodeComponent(message) : null;
    final uriStr = encoded != null
        ? 'https://wa.me/$normalizedPhone?text=$encoded'
        : 'https://wa.me/$normalizedPhone';

    final uri = Uri.parse(uriStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[WhatsApp] Açılamadı: $uriStr');
    }
  }
}

/// Singleton erişim noktası.
final whatsappService = WhatsappService();
