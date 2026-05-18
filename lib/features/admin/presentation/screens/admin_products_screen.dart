import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/products/data/models/product_model.dart';
import '../providers/admin_products_provider.dart';
import '../widgets/admin_sidebar.dart';

const double _kDesktopBreakpoint = 1024.0;
const double _kTabletBreakpoint = 700.0;

// ---------------------------------------------------------------------------
// AdminProductsScreen — ana ekran
// ---------------------------------------------------------------------------
class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;

    if (isDesktop) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Row(
          children: [
            AdminSidebar(),
            Expanded(child: _ProductsContent()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const AdminDrawerWrapper(),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Urun Yonetimi',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        elevation: 0,
      ),
      body: const _ProductsContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductsContent — asil icerik
// ---------------------------------------------------------------------------
class _ProductsContent extends ConsumerWidget {
  const _ProductsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(adminProductsProvider);

    return asyncProducts.when(
      loading: () => const _ProductsShimmer(),
      error: (e, _) => _ProductsError(error: e),
      data: (_) => const _ProductsBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductsBody — header + stats + tablo + sayfalama
// ---------------------------------------------------------------------------
class _ProductsBody extends ConsumerWidget {
  const _ProductsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductsHeader(isDesktop: isDesktop),
          const SizedBox(height: 20),
          const _StatsBar(),
          const SizedBox(height: 20),
          const _ProductsTable(),
          const SizedBox(height: 16),
          const _PaginationRow(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductsHeader — baslik + arama + filtre + ekle butonu
// ---------------------------------------------------------------------------
class _ProductsHeader extends ConsumerWidget {
  const _ProductsHeader({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(productSearchProvider);
    final catFilter = ref.watch(productCategoryFilterProvider);

    if (isDesktop) {
      return Row(
        children: [
          const _TitleBlock(),
          const Spacer(),
          _SearchField(value: search),
          const SizedBox(width: 12),
          _CategoryDropdown(value: catFilter),
          const SizedBox(width: 12),
          _AddProductButton(isDesktop: isDesktop),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _TitleBlock(),
            const Spacer(),
            _AddProductButton(isDesktop: isDesktop),
          ],
        ),
        const SizedBox(height: 12),
        _SearchField(value: search),
        const SizedBox(height: 8),
        _CategoryDropdown(value: catFilter),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urun Yonetimi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Urunleri ekle, duzenle ve yonet',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({required this.value});
  final String value;

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 44,
      child: TextField(
        controller: _ctrl,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Urun ara...',
          hintStyle: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        onChanged: (v) =>
            ref.read(productSearchProvider.notifier).set(v),
      ),
    );
  }
}

class _CategoryDropdown extends ConsumerWidget {
  const _CategoryDropdown({required this.value});
  final String? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text(
            'Tumunu Goster',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
            ),
          ),
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          onChanged: (v) =>
              ref.read(productCategoryFilterProvider.notifier).set(v),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tumunu Goster'),
            ),
            ...ProductCategory.all.map(
              (c) => DropdownMenuItem<String>(
                value: c['id'],
                child: Text(c['name']!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProductButton extends StatelessWidget {
  const _AddProductButton({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push(AppRoutes.productNew),
      icon: const Icon(Icons.add, size: 18),
      label: Text(isDesktop ? 'Yeni Urun Ekle' : 'Ekle'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatsBar — 4 istatistik kutusu
// ---------------------------------------------------------------------------
class _StatsBar extends ConsumerWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(adminProductsProvider);
    final products = asyncProducts.value ?? [];

    final total = products.length;
    final active = products.where((p) => p.isActive).length;
    final inactive = total - active;
    // Stok bilgisi variant'ta olduğu için burada 0 gösterilir;
    // doğru stok bilgisi her satırın _StockCell'inde görünür.
    final lowStock = 0;

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= _kTabletBreakpoint;

    return isTablet
        ? Row(
            children: [
              Expanded(child: _StatCard(label: 'Toplam Urun', value: '$total',
                  color: AppColors.secondary)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Aktif', value: '$active',
                  color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Pasif', value: '$inactive',
                  color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Dusuk Stok', value: '$lowStock',
                  color: AppColors.error)),
            ],
          )
        : GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _StatCard(label: 'Toplam Urun', value: '$total',
                  color: AppColors.secondary),
              _StatCard(label: 'Aktif', value: '$active',
                  color: AppColors.success),
              _StatCard(label: 'Pasif', value: '$inactive',
                  color: AppColors.textSecondary),
              _StatCard(label: 'Dusuk Stok', value: '$lowStock',
                  color: AppColors.error),
            ],
          );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductsTable — DataTable + overflow icin SingleChildScrollView
// ---------------------------------------------------------------------------
class _ProductsTable extends ConsumerWidget {
  const _ProductsTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(paginatedProductsProvider);
    final filtered = ref.watch(filteredProductsProvider);

    if (filtered.isEmpty) {
      return const _EmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFFF8F9FA),
            ),
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
            dividerThickness: 1,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Gorsel')),
              DataColumn(label: Text('Urun Adi')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Fiyat'), numeric: true),
              DataColumn(label: Text('Indirim'), numeric: true),
              DataColumn(label: Text('Stok'), numeric: true),
              DataColumn(label: Text('Durum')),
              DataColumn(label: Text('Islemler')),
            ],
            rows: products.map((p) => _buildRow(context, ref, p)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, ProductModel p) {
    return DataRow(
      cells: [
        // Gorsel
        DataCell(_ProductImage(imageUrl: p.imageUrl)),
        // Urun adi
        DataCell(
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  p.unit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
        // Kategori
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ProductCategory.nameForId(p.categoryId),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        // Fiyat
        DataCell(_PriceCell(product: p)),
        // Indirim — denormalized alanlardan hesaplanir, ekstra okuma yok
        DataCell(_DiscountCell(product: p)),
        // Stok
        DataCell(_StockCell(product: p)),
        // Durum
        DataCell(
          Switch(
            value: p.isActive,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
            onChanged: (_) =>
                ref.read(adminProductsProvider.notifier).toggleActive(p.id),
          ),
        ),
        // Islemler
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIcon(
                icon: Icons.edit_outlined,
                color: AppColors.secondary,
                tooltip: 'Duzenle',
                onTap: () => context.push('/admin/products/${p.id}/edit'),
              ),
              const SizedBox(width: 8),
              _ActionIcon(
                icon: Icons.delete_outline,
                color: AppColors.error,
                tooltip: 'Sil',
                onTap: () => _confirmDelete(context, ref, p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductModel p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Urunu Sil',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '"${p.name}" urununu silmek istediginizden emin misiniz? Bu islem geri alinamaz.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Iptal',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(adminProductsProvider.notifier).deleteProduct(p.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Urun silindi.',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Sil',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        color: AppColors.imageBg,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return const Icon(
      Icons.water_drop_outlined,
      size: 22,
      color: AppColors.textHint,
    );
  }
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    // Koli varsa koli fiyati, yoksa primary fiyati goster
    final double? price = product.koliPrice ?? product.primaryPrice;
    final double? salePrice = product.koliSalePrice ?? product.primarySalePrice;

    if (price == null || price == 0) {
      return const Text(
        '—',
        style: TextStyle(
          color: AppColors.textHint,
          fontFamily: 'Poppins',
          fontSize: 13,
        ),
      );
    }

    final effectiveSale =
        (salePrice != null && salePrice > 0 && salePrice < price)
            ? salePrice
            : null;

    if (effectiveSale != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₺${effectiveSale.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            '₺${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }

    return Text(
      '₺${price.toStringAsFixed(2)}',
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DiscountCell extends StatelessWidget {
  const _DiscountCell({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    if (!product.hasDiscount) {
      return const Text(
        '-',
        style: TextStyle(color: AppColors.textHint, fontFamily: 'Poppins'),
      );
    }
    return Text(
      '%${product.discountPercent.toStringAsFixed(0)}',
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _StockCell extends StatelessWidget {
  const _StockCell({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    // Koli stoku varsa onu, yoksa primary stoku goster
    final stock = product.koliStock ?? product.primaryStock ?? 0;
    final isInStock = product.inStock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInStock
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isInStock ? '$stock adet' : 'Tukendi',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isInStock ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PaginationRow
// ---------------------------------------------------------------------------
class _PaginationRow extends ConsumerWidget {
  const _PaginationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(productsPageProvider);
    final totalPages = ref.watch(totalProductPagesProvider);
    final filteredCount = ref.watch(filteredProductsProvider).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$filteredCount urun',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: page > 0
              ? () =>
                  ref.read(productsPageProvider.notifier).set(page - 1)
              : null,
          color: AppColors.secondary,
          disabledColor: AppColors.textHint,
        ),
        Text(
          '${page + 1} / $totalPages',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: page < totalPages - 1
              ? () =>
                  ref.read(productsPageProvider.notifier).set(page + 1)
              : null,
          color: AppColors.secondary,
          disabledColor: AppColors.textHint,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bos durum
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'Urun bulunamadi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Arama kriterlerinizi degistirin veya yeni urun ekleyin.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------
class _ProductsShimmer extends StatelessWidget {
  const _ProductsShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 200, height: 28),
          const SizedBox(height: 8),
          _ShimmerBox(width: 280, height: 16),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _ShimmerBox(width: double.infinity, height: 60)),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerBox(width: double.infinity, height: 60)),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerBox(width: double.infinity, height: 60)),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerBox(width: double.infinity, height: 60)),
          ]),
          const SizedBox(height: 24),
          _ShimmerBox(width: double.infinity, height: 400),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim =
        Tween<double>(begin: -1.5, end: 1.5).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFF5F5F5),
              Color(0xFFEEEEEE),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hata durumu
// ---------------------------------------------------------------------------
class _ProductsError extends StatelessWidget {
  const _ProductsError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Urunler yuklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
