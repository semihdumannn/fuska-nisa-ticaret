import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataVersions {
  final DateTime? products;
  final DateTime? categories;
  final DateTime? variants;

  const DataVersions({this.products, this.categories, this.variants});
}

/// Firestore `settings/data_versions` polling kaldırıldı.
/// Backend artık HF Space REST API üzerinden çalıştığından
/// Firestore data version senkronizasyonu gerekli değil.
///
/// Cache invalidation artık şu şekilde yönetilir:
///   - TTL bazlı: CacheService'teki isFresh() kontrolü
///   - Manuel: Admin yazma sonrası CacheService.clear() çağrısı
///
/// Bu provider geriye dönük uyumluluk için sabit bir DataVersions nesnesi döndürür.
/// Bağlı consumer'lar stream'i dinlemeye devam edebilir — hiçbir şey emit etmez
/// (stream tamamlanmaz, sadece başlangıç değeri yayınlanır).
final dataVersionProvider = StreamProvider<DataVersions>((ref) async* {
  yield const DataVersions();
});
