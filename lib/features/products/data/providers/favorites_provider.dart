import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFavKey = 'favorite_product_ids';

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kFavKey) ?? [];
    return raw.toSet();
  }

  Future<void> toggle(String productId) async {
    final current = state.value ?? {};
    final next = Set<String>.from(current);
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavKey, next.toList());
  }

  bool isFavorite(String productId) => state.value?.contains(productId) ?? false;
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);
