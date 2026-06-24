import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/favorite_remote_datasource.dart';

final _favoriteDatasourceProvider = Provider<FavoriteRemoteDatasource>(
  (ref) => FavoriteRemoteDatasource(ref.watch(apiClientProvider).dio),
);

// State: Map<productId, favoriteRecordId>
// favoriteRecordId DELETE için gerekli (product_id değil).
class FavoritesNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() async {
    try {
      return await ref.read(_favoriteDatasourceProvider).getFavorites();
    } catch (e) {
      if (kDebugMode) debugPrint('[Favorites] load hatası: $e');
      return {};
    }
  }

  Future<void> toggle(String productId) async {
    final current = state.value ?? {};
    if (current.containsKey(productId)) {
      // Sil — optimistic
      final favoriteId = current[productId]!;
      final next = Map<String, int>.from(current)..remove(productId);
      state = AsyncData(next);
      try {
        await ref.read(_favoriteDatasourceProvider).removeFavorite(favoriteId);
      } catch (e) {
        state = AsyncData(current);
        if (kDebugMode) debugPrint('[Favorites] remove hatası: $e');
      }
    } else {
      // Ekle — optimistic UI: geçici -1 ID
      final optimistic = Map<String, int>.from(current)..[productId] = -1;
      state = AsyncData(optimistic);
      try {
        final newId =
            await ref.read(_favoriteDatasourceProvider).addFavorite(productId);
        final confirmed =
            Map<String, int>.from(state.value ?? optimistic)..[productId] = newId;
        state = AsyncData(confirmed);
      } catch (e) {
        state = AsyncData(current);
        if (kDebugMode) debugPrint('[Favorites] add hatası: $e');
      }
    }
  }

  bool isFavorite(String productId) =>
      state.value?.containsKey(productId) ?? false;
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Map<String, int>>(
  FavoritesNotifier.new,
);
