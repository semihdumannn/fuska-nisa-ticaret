import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ürün formu için varyant okuma/yazma operasyonları.
///
/// NOT: Varyant CRUD API endpoint'i mevcut değil.
/// Bu repository şu an stub implementasyona dönüştürülmüştür;
/// tüm metodlar [UnsupportedVariantOperationException] fırlatır ya da
/// boş liste döndürür.
///
/// İleride API endpoint eklendiğinde bu repository Dio tabanlı
/// implementasyonla değiştirilmeli.
class UnsupportedVariantOperationException implements Exception {
  const UnsupportedVariantOperationException();

  @override
  String toString() => 'Varyant yönetimi şu an desteklenmiyor';
}

class AdminVariantRepository {
  // ─── Read ────────────────────────────────────────────────────────────────────

  /// Varyant API endpoint'i olmadığından boş liste döndürür.
  Future<List<Map<String, dynamic>>> getVariantsByProduct(
      String productId) async {
    return [];
  }

  // ─── Write ───────────────────────────────────────────────────────────────────

  /// Varyant API endpoint'i olmadığından bu işlem desteklenmiyor.
  Future<void> saveProductWithVariants({
    required String productDocId,
    required Map<String, dynamic> productData,
    required bool isNewProduct,
    required List<VariantWriteEntry> variantEntries,
    required List<String> variantIdsToDelete,
  }) async {
    throw const UnsupportedVariantOperationException();
  }

  /// Yeni varyant için pseudo-ID üretir (lokal, ağ çağrısı yapmaz).
  String allocateVariantId() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Tek bir varyant yazma isteği.
class VariantWriteEntry {
  final String firestoreId;
  final Map<String, dynamic> data;

  /// true → güncelleme, false → yeni ekleme
  final bool isExisting;

  const VariantWriteEntry({
    required this.firestoreId,
    required this.data,
    required this.isExisting,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

final adminVariantRepositoryProvider = Provider<AdminVariantRepository>((ref) {
  return AdminVariantRepository();
});
