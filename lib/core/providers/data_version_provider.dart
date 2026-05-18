import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';

class DataVersions {
  final DateTime? products;
  final DateTime? categories;
  final DateTime? variants;

  const DataVersions({this.products, this.categories, this.variants});
}

/// Firestore `settings/data_versions` dökümanını dinler.
/// Admin bir ürün kaydettiğinde bu döküman güncellenir;
/// ilgili Hive cache anahtarları temizlenir ve bağlı FutureProvider'lar
/// yeniden inşa edilerek güncel veri çeker.
final dataVersionProvider = StreamProvider<DataVersions>((ref) {
  DateTime? lastVariantsUpdate;

  return FirebaseFirestore.instance
      .collection('settings')
      .doc('data_versions')
      .snapshots()
      .map((snap) {
        final data = snap.data() ?? {};

        DateTime? parseTs(String key) {
          final v = data[key];
          return v is Timestamp ? v.toDate() : null;
        }

        final versions = DataVersions(
          products: parseTs('productsUpdatedAt'),
          categories: parseTs('categoriesUpdatedAt'),
          variants: parseTs('variantsUpdatedAt'),
        );

        // Ürünler: remote timestamp > local cache yazım zamanı → temizle
        if (versions.products != null) {
          final localTime = cacheService.getCacheTime('products_all_v2');
          if (localTime == null || versions.products!.isAfter(localTime)) {
            cacheService.clear('products_all_v2').ignore();
            cacheService.clear('products_featured_v2').ignore();
            cacheService.clearByPattern('products_cat_').ignore();
          }
        }

        // Kategoriler: aynı mantık
        if (versions.categories != null) {
          final localTime = cacheService.getCacheTime('categories_v2');
          if (localTime == null || versions.categories!.isAfter(localTime)) {
            cacheService.clear('categories_v2').ignore();
          }
        }

        // Varyantlar: oturum içinde değişim varsa tüm varyant cache'ini temizle
        if (versions.variants != null &&
            versions.variants != lastVariantsUpdate) {
          if (lastVariantsUpdate != null) {
            cacheService.clearByPattern('variants_').ignore();
          }
          lastVariantsUpdate = versions.variants;
        }

        return versions;
      });
});
