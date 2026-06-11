import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/cart/data/models/cart_model.dart';
import 'package:nisa_ticaret/features/cart/presentation/bloc/cart_provider.dart';
import 'package:nisa_ticaret/features/home/widgets/product_card.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/models/variant_model.dart';
import 'package:nisa_ticaret/features/products/data/repositories/product_repository.dart';
import 'package:nisa_ticaret/features/products/presentation/bloc/product_detail_provider.dart';

/// Urun detay sayfasi.
/// - Carousel (coklu gorsel) veya tek gorsel
/// - Fiyat + indirim badge
/// - Expandable aciklama
/// - Miktar secici (min/max kontrollu)
/// - Sepete ekle butonu
/// - Ilgili urunler (ayni kategori, max 10, yatay liste)
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  bool _qtyInitialized = false;
  int _carouselIndex = 0;
  bool _descriptionExpanded = false;
  VariantModel? _selectedVariant;

  void _initQty(ProductModel product, CartModel cart) {
    if (_qtyInitialized) return;
    _qtyInitialized = true;
    final minQty = _selectedVariant?.minOrderQty ?? product.minOrderQty;
    final cartQty = cart.containsProduct(
      product.id,
      variantId: _selectedVariant?.id,
    )
        ? cart.quantityOf(product.id, variantId: _selectedVariant?.id)
        : minQty;
    _qty = cartQty.clamp(minQty, max(minQty, 1));
  }

  void _increment(ProductModel product) {
    final maxQty = _selectedVariant?.maxOrderQty ?? product.maxOrderQty;
    final stockQty = _selectedVariant?.stock ?? product.stock;
    final effectiveMax = min(maxQty, stockQty);
    if (_qty < effectiveMax) setState(() => _qty++);
  }

  void _decrement(ProductModel product) {
    final minQty = _selectedVariant?.minOrderQty ?? product.minOrderQty;
    if (_qty > minQty) setState(() => _qty--);
  }

  void _addToCart(ProductModel product) {
    final cart = ref.read(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final variantId = _selectedVariant?.id;

    if (cart.containsProduct(product.id, variantId: variantId)) {
      notifier.updateQuantity(product.id, _qty, variantId: variantId);
    } else {
      notifier.addItem(product, variant: _selectedVariant, quantity: _qty);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} sepete eklendi'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final cartCount = ref.watch(cartProvider.select((c) => c.totalItems));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => _buildShimmer(context, cartCount),
        error: (e, _) => _buildError(context),
        data: (product) {
          if (product == null) {
            return _buildNotFound(context);
          }
          final cart = ref.watch(cartProvider);
          _initQty(product, cart);
          return _buildContent(context, product, cartCount);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Ana içerik
  // ─────────────────────────────────────────────

  Widget _buildContent(
      BuildContext context, ProductModel product, int cartCount) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, product, cartCount),
        SliverToBoxAdapter(
          child: _buildInfoCard(context, product),
        ),
        SliverToBoxAdapter(
          child: _buildRelatedSection(context, product),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SliverAppBar - gorsel carousel
  // ─────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar(
      BuildContext context, ProductModel product, int cartCount) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: _CircleIconButton(
        icon: Icons.arrow_back,
        onPressed: () => context.pop(),
      ),
      actions: [
        _CartIconButton(cartCount: cartCount),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _ProductImageCarousel(
          images: product.allImages,
          currentIndex: _carouselIndex,
          onIndexChanged: (index) => setState(() => _carouselIndex = index),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Bilgi karti - gorsel altini kaplar
  // ─────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context, ProductModel product) {
    // variantsByProductProvider yerine ProductModel.koliVariant kullan.
    // koliVariant anında mevcut — ekstra API çağrısı yok.
    final koliVariant = product.koliVariant;
    final variants = koliVariant != null ? [koliVariant] : <VariantModel>[];
    final hasVariants = variants.isNotEmpty;

    // İlk yüklenmede koli varyantını otomatik seç
    if (_selectedVariant == null && koliVariant != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedVariant = koliVariant);
      });
    }

    // Seçili varyant varsa ondan, yoksa ürünün kendi fiyat/stok alanlarından al
    final effectivePrice =
        _selectedVariant?.effectivePrice ?? product.effectivePrice;
    final hasDiscount =
        _selectedVariant?.hasDiscount ?? product.hasDiscount;
    final discountPercent =
        _selectedVariant?.discountPercent.toInt() ?? product.discountPercent.toInt();
    final originalPrice = _selectedVariant?.price ?? product.price;
    final isProductInStock = _selectedVariant?.inStock ?? product.inStock;
    final minQty = _selectedVariant?.minOrderQty ?? product.minOrderQty;
    final maxQty = _selectedVariant != null
        ? min(_selectedVariant!.maxOrderQty, _selectedVariant!.stock)
        : product.maxOrderQty;

    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urun adi + indirim badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  _DiscountBadge(percent: discountPercent),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Varyant gösterimi — anında mevcut, loading yok
            if (hasVariants)
              if (variants.length == 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildKoliLabel(variants.first),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Secim',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: variants
                            .map(
                              (v) => _VariantChip(
                                variant: v,
                                isSelected: _selectedVariant?.id == v.id,
                                onTap: () {
                                  setState(() {
                                    _selectedVariant = v;
                                    _qty = v.minOrderQty;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

            // Fiyat satiri
            if (_selectedVariant != null || !hasVariants)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (hasDiscount) ...[
                    Text(
                      '${originalPrice.toStringAsFixed(2)} TL',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    effectivePrice > 0
                        ? '${effectivePrice.toStringAsFixed(2)} TL'
                        : 'Fiyat yok',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: effectivePrice > 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (hasVariants && _selectedVariant != null) ...[
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '/ koli',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if ((_selectedVariant!.packageQty ?? 0) > 0)
                          Text(
                            '1 Koli = ${_selectedVariant!.packageQty} Adet',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),

            const SizedBox(height: 12),

            // Stok durumu (varyant seciliyse goster)
            if (_selectedVariant != null)
              _VariantStockBadge(variant: _selectedVariant!),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.divider, height: 1),
            ),

            // Expandable aciklama
            _ExpandableDescription(
              description: product.description,
              expanded: _descriptionExpanded,
              onToggle: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
            ),

            const SizedBox(height: 24),

            // Miktar secici + Sepete ekle
            Row(
              children: [
                _QtySelector(
                  qty: _qty,
                  onDecrement:
                      isProductInStock ? () => _decrement(product) : null,
                  onIncrement:
                      (isProductInStock && _qty < maxQty)
                          ? () => _increment(product)
                          : null,
                  canDecrement: _qty > minQty,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: (isProductInStock &&
                            (_selectedVariant != null || !hasVariants))
                        ? () => _addToCart(product)
                        : null,
                    child: Text(
                      !isProductInStock
                          ? 'Stok Tukendi'
                          : (hasVariants && _selectedVariant == null)
                              ? 'Varyant Secin'
                              : 'Sepete Ekle',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Koli etiketi (tek varyant durumunda chip yerine)
  // ─────────────────────────────────────────────

  Widget _buildKoliLabel(VariantModel variant) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Koli',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        if ((variant.packageQty ?? 0) > 0) ...[
          const SizedBox(width: 8),
          Text(
            '1 Koli = ${variant.packageQty} Adet',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Ilgili urunler bolumu
  // ─────────────────────────────────────────────

  Widget _buildRelatedSection(BuildContext context, ProductModel product) {
    if (product.categoryIds.isEmpty) return const SizedBox.shrink();

    final relatedAsync =
        ref.watch(productsByCategoryProvider(product.categoryIds.first));

    return relatedAsync.when(
      loading: () => _buildRelatedShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final related = all
            .where((p) => p.id != product.id)
            .take(10)
            .toList();

        if (related.isEmpty) return const SizedBox.shrink();

        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Divider(color: AppColors.divider, height: 1),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Text(
                  'Benzer Ürünler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 160,
                    child: ProductCard(product: related[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelatedShimmer() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: AppColors.border,
            highlightColor: AppColors.surface,
            child: Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Shimmer.fromColors(
              baseColor: AppColors.border,
              highlightColor: AppColors.surface,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Yukleniyor shimmer (tam sayfa)
  // ─────────────────────────────────────────────

  Widget _buildShimmer(BuildContext context, int cartCount) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: _CircleIconButton(
            icon: Icons.arrow_back,
            onPressed: () => context.pop(),
          ),
          actions: [
            _CartIconButton(cartCount: cartCount),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Shimmer.fromColors(
              baseColor: AppColors.border,
              highlightColor: AppColors.surface,
              child: Container(color: Colors.white),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Shimmer.fromColors(
              baseColor: AppColors.border,
              highlightColor: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 28,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 20,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Hata / bulunamadı durumlari
  // ─────────────────────────────────────────────

  Widget _buildError(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ürün yüklenemedi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      ref.invalidate(productDetailProvider(widget.productId)),
                  child: const Text('Tekrar Dene'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Ürün bulunamadı',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Gorsel Carousel
// ─────────────────────────────────────────────

class _ProductImageCarousel extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _ProductImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return _buildPlaceholder();
    }

    if (images.length == 1) {
      return _buildSingleImage(images.first);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: double.infinity,
            viewportFraction: 1.0,
            enableInfiniteScroll: images.length > 1,
            autoPlay: images.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 500),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (index, reason) => onIndexChanged(index),
          ),
          items: images.map((url) => _buildNetworkImage(url)).toList(),
        ),
        // Nokta gostergeleri
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final isActive = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
        // Gorsel sayaci
        Positioned(
          top: 56,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentIndex + 1}/${images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImage(String url) {
    return _buildNetworkImage(url);
  }

  Widget _buildNetworkImage(String url) {
    return Container(
      color: AppColors.imageBg,
      padding: const EdgeInsets.all(16),
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        fit: BoxFit.contain,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.border,
          highlightColor: AppColors.surface,
          child: Container(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.secondary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Icons.water_drop,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Indirim badge
// ─────────────────────────────────────────────

class _DiscountBadge extends StatelessWidget {
  final int percent;

  const _DiscountBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '%$percent İndirim',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Varyant stok durumu badge
// ─────────────────────────────────────────────

class _VariantStockBadge extends StatelessWidget {
  final VariantModel variant;

  const _VariantStockBadge({required this.variant});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          variant.inStock ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: variant.inStock ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: 6),
        Text(
          variant.inStock ? 'Stokta var' : 'Stok tukendi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: variant.inStock ? AppColors.success : AppColors.error,
          ),
        ),
        if (variant.inStock && variant.stock <= 10) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Son ${variant.stock} adet',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Varyant secim chip'i
// ─────────────────────────────────────────────

class _VariantChip extends StatelessWidget {
  final VariantModel variant;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantChip({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: variant.inStock ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              variant.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${variant.effectivePrice.toStringAsFixed(2)} TL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (!variant.inStock)
              const Text(
                'Stok yok',
                style: TextStyle(fontSize: 10, color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Expandable aciklama
// ─────────────────────────────────────────────

class _ExpandableDescription extends StatelessWidget {
  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  static const int _collapseLineCount = 3;

  const _ExpandableDescription({
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final text = description.isNotEmpty ? description : 'Açıklama bulunmuyor.';
    final needsExpand = description.length > 120;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün Açıklaması',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeOut,
          crossFadeState: expanded || !needsExpand
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            text,
            maxLines: _collapseLineCount,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          secondChild: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        if (needsExpand)
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Daha Az Göster' : 'Devamını Göster',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Miktar secici
// ─────────────────────────────────────────────

class _QtySelector extends StatelessWidget {
  final int qty;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool canDecrement;

  const _QtySelector({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
    required this.canDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: canDecrement ? onDecrement : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$qty',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 44,
          child: Icon(
            icon,
            size: 18,
            color: onTap != null ? AppColors.secondary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Yuvarlak ikon butonu (geri, favori)
// ─────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sepet ikonu (badge ile)
// ─────────────────────────────────────────────

class _CartIconButton extends ConsumerWidget {
  final int cartCount;

  const _CartIconButton({required this.cartCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.go(AppRoutes.cart),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (cartCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    cartCount > 99 ? '99+' : '$cartCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
