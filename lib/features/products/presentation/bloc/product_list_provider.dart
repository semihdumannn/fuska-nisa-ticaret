import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';

enum SortOption { nameAsc, nameDesc, priceAsc, priceDesc, popularity }

@immutable
class ProductListState {
  final String searchQuery;
  final String? selectedCategoryId;
  /// Birden fazla kategori ID'si ile filtreleme (kök kategori seçildiğinde alt kategoriler dahil).
  final Set<String>? categoryFilterIds;
  final SortOption sortOption;
  final int currentPage;

  const ProductListState({
    this.searchQuery = '',
    this.selectedCategoryId,
    this.categoryFilterIds,
    this.sortOption = SortOption.popularity,
    this.currentPage = 1,
  });

  List<ProductModel> filteredProducts(List<ProductModel> all) {
    var result = _filteredUnpaged(all);

    result = List<ProductModel>.from(result)..sort((a, b) {
      switch (sortOption) {
        case SortOption.nameAsc:
          return a.name.compareTo(b.name);
        case SortOption.nameDesc:
          return b.name.compareTo(a.name);
        case SortOption.priceAsc:
          return a.effectivePrice.compareTo(b.effectivePrice);
        case SortOption.priceDesc:
          return b.effectivePrice.compareTo(a.effectivePrice);
        case SortOption.popularity:
          return a.order.compareTo(b.order);
      }
    });

    return result.take(currentPage * AppConstants.pageSize).toList();
  }

  bool hasMore(List<ProductModel> all) {
    final filtered = _filteredUnpaged(all);
    return currentPage * AppConstants.pageSize < filtered.length;
  }

  List<ProductModel> _filteredUnpaged(List<ProductModel> all) {
    var result = all;

    if (categoryFilterIds != null && categoryFilterIds!.isNotEmpty) {
      result = result.where((p) => p.categoryIds.any((id) => categoryFilterIds!.contains(id))).toList();
    } else if (selectedCategoryId != null) {
      result = result.where((p) => p.categoryIds.contains(selectedCategoryId)).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(query)).toList();
    }

    return result;
  }

  ProductListState copyWith({
    String? searchQuery,
    Object? selectedCategoryId = _sentinel,
    Object? categoryFilterIds = _sentinel,
    SortOption? sortOption,
    int? currentPage,
  }) {
    return ProductListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId == _sentinel
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      categoryFilterIds: categoryFilterIds == _sentinel
          ? this.categoryFilterIds
          : categoryFilterIds as Set<String>?,
      sortOption: sortOption ?? this.sortOption,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  /// Kök kategori seçiliyse ve altında birden fazla kategori varsa true.
  bool get hasRootCategorySelected =>
      selectedCategoryId != null &&
      categoryFilterIds != null &&
      categoryFilterIds!.length > 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductListState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          selectedCategoryId == other.selectedCategoryId &&
          sortOption == other.sortOption &&
          currentPage == other.currentPage;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      selectedCategoryId.hashCode ^
      sortOption.hashCode ^
      currentPage.hashCode;
}

// Sentinel value for nullable copyWith
const _sentinel = Object();

class ProductListNotifier extends Notifier<ProductListState> {
  @override
  ProductListState build() => const ProductListState();

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      categoryFilterIds: null,
      currentPage: 1,
    );
  }

  /// Kök kategori seçildiğinde subcategory ID'leri ile birlikte filtrele.
  void setRootCategory(String rootId, List<String> subIds) {
    final allIds = {rootId, ...subIds};
    state = state.copyWith(
      selectedCategoryId: rootId,
      categoryFilterIds: allIds,
      currentPage: 1,
    );
  }

  void setSortOption(SortOption option) {
    state = state.copyWith(sortOption: option, currentPage: 1);
  }

  void loadNextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void reset() {
    state = const ProductListState();
  }
}

final productListProvider =
    NotifierProvider<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
);
