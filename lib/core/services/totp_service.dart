import 'package:dio/dio.dart';
import 'package:otp/otp.dart';
import '../network/api_endpoints.dart';

/// Cihaz-bağlı TOTP (RFC 6238) kod üretimi.
///
/// Backend ile saat senkronizasyonu için sunucu zamanı çekilip cihaz zamanıyla
/// arasındaki fark (offset) hesaplanır; kod üretirken bu offset uygulanır.
class TotpService {
  final Dio _dio;

  // Sunucu-cihaz zaman farkı kısa süreli cache'lenir.
  int? _cachedOffsetMs;
  DateTime? _offsetFetchedAt;
  static const _offsetTtl = Duration(hours: 1);

  TotpService(this._dio);

  /// Sunucu-cihaz zaman farkını ms cinsinden döner (sunucu - cihaz).
  Future<int> getServerTimeOffsetMs() async {
    if (_cachedOffsetMs != null &&
        _offsetFetchedAt != null &&
        DateTime.now().difference(_offsetFetchedAt!) < _offsetTtl) {
      return _cachedOffsetMs!;
    }

    try {
      final response = await _dio.get(ApiEndpoints.serverTime);
      final serverTimestamp = response.data['timestamp'] as int;
      final offset = serverTimestamp * 1000 - DateTime.now().millisecondsSinceEpoch;
      _cachedOffsetMs = offset;
      _offsetFetchedAt = DateTime.now();
      return offset;
    } catch (_) {
      // Sunucuya ulaşılamazsa offset 0 kabul edilir (cihaz saati doğru varsayılır).
      return _cachedOffsetMs ?? 0;
    }
  }

  /// Base32 secret'tan, offset uygulanmış cihaz zamanına göre 6 haneli TOTP kodu üretir.
  String generateCode(String base32Secret, int offsetMs) {
    final time = DateTime.now().millisecondsSinceEpoch + offsetMs;
    return OTP.generateTOTPCodeString(
      base32Secret,
      time,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }
}
