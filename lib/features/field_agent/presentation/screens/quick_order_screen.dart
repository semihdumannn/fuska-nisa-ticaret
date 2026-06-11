import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/repositories/product_repository.dart';

// ---------------------------------------------------------------------------
// Teslimat saati secenekleri
// ---------------------------------------------------------------------------
const List<String> _kTimeSlots = [
  'Bugün 10:00 - 12:00',
  'Bugün 12:00 - 14:00',
  'Bugün 14:00 - 16:00',
  'Bugün 16:00 - 18:00',
  'Yarın 09:00 - 11:00',
  'Yarın 11:00 - 13:00',
];

// ---------------------------------------------------------------------------
// QuickOrderScreen
// ---------------------------------------------------------------------------
class QuickOrderScreen extends ConsumerStatefulWidget {
  final UserModel? customer;

  const QuickOrderScreen({super.key, this.customer});

  @override
  ConsumerState<QuickOrderScreen> createState() => _QuickOrderScreenState();
}

class _QuickOrderScreenState extends ConsumerState<QuickOrderScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  final Map<String, int> _quantities = {};
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  String _searchQuery = '';
  String? _selectedTimeSlot;
  bool _isLoading = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  // Misafir müşteri bilgileri (widget.customer == null ise kullanılır)
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();
  final TextEditingController _guestAddressController = TextEditingController();

  // ── Computed ───────────────────────────────────────────────────────────────
  double get _totalAmount {
    double total = 0;
    for (final entry in _quantities.entries) {
      if (entry.value > 0) {
        try {
          final product = _allProducts.firstWhere((p) => p.id == entry.key);
          total += product.effectivePrice * entry.value;
        } catch (_) {
          // Urun listede bulunamazsa atla
        }
      }
    }
    return total;
  }

  int get _selectedCount =>
      _quantities.values.where((q) => q > 0).length;

  List<MapEntry<String, int>> get _selectedEntries =>
      _quantities.entries.where((e) => e.value > 0).toList();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestAddressController.dispose();
    super.dispose();
  }

  void _onProductsLoaded(List<ProductModel> products) {
    final active = products
        .where((p) => p.isActive && p.inStock)
        .toList();
    if (_allProducts.length == active.length) return;
    setState(() {
      _allProducts = active;
      _filterProducts();
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.unit.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _setQty(String productId, int qty) {
    setState(() {
      if (qty <= 0) {
        _quantities.remove(productId);
      } else {
        _quantities[productId] = qty;
      }
    });
  }

  // ── Siparis ver ────────────────────────────────────────────────────────────
  Future<void> _placeOrder() async {
    if (_selectedCount == 0) return;
    setState(() => _isLoading = true);
    try {
      final agent = ref.read(authStateProvider).value;
      if (agent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum bulunamadı, lütfen tekrar giriş yapın.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      final now = DateTime.now();

      final items = <OrderItem>[];
      for (final entry in _quantities.entries) {
        if (entry.value > 0) {
          final p = _allProducts.firstWhere((p) => p.id == entry.key);
          items.add(OrderItem(
            productId: p.id,
            productName: p.name,
            imageUrl: p.imageUrl,
            qty: entry.value,
            unitPrice: p.effectivePrice,
            totalPrice: p.effectivePrice * entry.value,
          ));
        }
      }

      final subtotal = items.fold(0.0, (s, i) => s + i.totalPrice);
      final deliveryNote = _selectedTimeSlot != null
          ? _selectedTimeSlot!
          : 'Saha terminali';

      final isGuest = widget.customer == null;
      final guestName = _guestNameController.text.trim();
      final guestPhone = _guestPhoneController.text.trim();
      final guestAddress = _guestAddressController.text.trim();

      final order = OrderModel(
        id: '',
        orderNo: '',
        customerId: widget.customer?.uid ?? agent.uid,
        customerName: widget.customer?.name ??
            (guestName.isNotEmpty ? guestName : 'Misafir Müşteri'),
        customerPhone: widget.customer?.phone ?? guestPhone,
        source: OrderSource.fieldAgent,
        createdBy: agent.uid,
        status: OrderStatus.pending,
        statusHistory: [
          StatusHistory(
            status: OrderStatus.pending,
            timestamp: now,
            by: agent.uid,
          ),
        ],
        items: items,
        deliveryAddress: DeliveryAddress(
          fullAddress: isGuest && guestAddress.isNotEmpty
              ? guestAddress
              : deliveryNote,
          district: '-',
          city: '-',
          notes: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        paymentMethod: _paymentMethod,
        subtotal: subtotal,
        discount: 0,
        total: subtotal,
        notes: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final orderNo =
          await ref.read(orderRepositoryProvider).createOrder(order);

      if (mounted) {
        context.go(AppRoutes.orderSuccess, extra: orderNo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş oluşturulamadı: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    productsAsync.whenData(_onProductsLoaded);

    final customerName = widget.customer?.name;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hızlı Sipariş Al',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (customerName != null)
              Text(
                customerName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: productsAsync.when(
              loading: _buildShimmer,
              error: (e, _) => _buildError(e),
              data: (_) => _buildScrollBody(),
            ),
          ),
          _BottomOrderBar(
            total: _totalAmount,
            selectedCount: _selectedCount,
            isLoading: _isLoading,
            onConfirm: _placeOrder,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CustomerCard(
            customer: widget.customer,
            onChangeTap: () => context.push(AppRoutes.customerSearch),
          ),
          if (widget.customer == null) ...[
            const SizedBox(height: 4),
            _GuestInfoForm(
              nameController: _guestNameController,
              phoneController: _guestPhoneController,
              addressController: _guestAddressController,
            ),
          ],
          const SizedBox(height: 12),
          _buildSearchField(),
          const SizedBox(height: 8),
          _buildProductList(),
          if (_selectedEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SelectedItemsSection(
              entries: _selectedEntries,
              allProducts: _allProducts,
              onRemove: (id) => _setQty(id, 0),
            ),
          ],
          const SizedBox(height: 16),
          _DeliverySection(
            selectedSlot: _selectedTimeSlot,
            noteController: _noteController,
            onSlotChanged: (v) => setState(() => _selectedTimeSlot = v),
          ),
          const SizedBox(height: 16),
          _PaymentSection(
            selected: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Ürün ara...',
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                color: AppColors.textSecondary,
                onPressed: () {
                  _searchController.clear();
                  // Listener otomatik tetiklenir
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '"$_searchQuery" için ürün bulunamadı.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Stokta ürün bulunmuyor.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (_, index) {
        final product = _filteredProducts[index];
        return _ProductRow(
          product: product,
          qty: _quantities[product.id] ?? 0,
          onQtyChanged: (qty) => _setQty(product.id, qty),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) => const _ShimmerRow(),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Ürünler yüklenemedi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(allProductsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CustomerCard
// ---------------------------------------------------------------------------
class _CustomerCard extends StatelessWidget {
  final UserModel? customer;
  final VoidCallback onChangeTap;

  const _CustomerCard({
    required this.customer,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: customer != null
          ? _buildCustomerInfo(context)
          : _buildEmptyState(context),
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    final initials = customer!.name.isNotEmpty
        ? customer!.name[0].toUpperCase()
        : 'M';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer!.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                customer!.phone,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onChangeTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(64, 44),
          ),
          child: const Text(
            'Değiştir',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person_add_outlined,
          size: 32,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        const Text(
          'Müşteri seçin veya misafir devam edin',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onChangeTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            minimumSize: const Size(160, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Müşteri Seç'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductRow
// ---------------------------------------------------------------------------
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final int qty;
  final ValueChanged<int> onQtyChanged;

  const _ProductRow({
    required this.product,
    required this.qty,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          _ProductImage(imageUrl: product.allImages.firstOrNull),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _PriceRow(product: product),
                const SizedBox(height: 2),
                Text(
                  'Stok: ${product.stock} ${product.unit}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QtyControl(
            qty: qty,
            maxQty: product.maxOrderQty,
            onChanged: onQtyChanged,
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.imageBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.water_drop_outlined,
        color: AppColors.accent,
        size: 24,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final ProductModel product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.hasDiscount) {
      return Row(
        children: [
          Text(
            '${product.effectivePrice.toStringAsFixed(2)} TL',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${product.price.toStringAsFixed(2)} TL',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '/ ${product.unit}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return Text(
      '${product.effectivePrice.toStringAsFixed(2)} TL / ${product.unit}',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final int maxQty;
  final ValueChanged<int> onChanged;

  const _QtyControl({
    required this.qty,
    required this.maxQty,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return SizedBox(
        width: 48,
        height: 48,
        child: InkWell(
          onTap: () => onChanged(1),
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.add, color: AppColors.textWhite, size: 20),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 44,
            child: InkWell(
              onTap: () => onChanged(qty - 1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                bottomLeft: Radius.circular(9),
              ),
              child: const Center(
                child: Icon(Icons.remove, color: AppColors.secondary, size: 16),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 44,
            child: InkWell(
              onTap: qty < maxQty ? () => onChanged(qty + 1) : null,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: qty < maxQty ? AppColors.secondary : AppColors.textHint,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SelectedItemsSection
// ---------------------------------------------------------------------------
class _SelectedItemsSection extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final List<ProductModel> allProducts;
  final ValueChanged<String> onRemove;

  const _SelectedItemsSection({
    required this.entries,
    required this.allProducts,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final count = entries.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seçilen Ürünler ($count çeşit)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          ...entries.map((entry) {
            final idx = allProducts.indexWhere((p) => p.id == entry.key);
            if (idx == -1) return const SizedBox.shrink();
            final product = allProducts[idx];
            final lineTotal = product.effectivePrice * entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: '  ×${entry.value}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${lineTotal.toStringAsFixed(2)} TL',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(entry.key),
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.error,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DeliverySection
// ---------------------------------------------------------------------------
class _DeliverySection extends StatelessWidget {
  final String? selectedSlot;
  final TextEditingController noteController;
  final ValueChanged<String?> onSlotChanged;

  const _DeliverySection({
    required this.selectedSlot,
    required this.noteController,
    required this.onSlotChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teslimat Saati',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            child: DropdownButton<String>(
              value: selectedSlot,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text(
                'Saat seçin (opsiyonel)',
                style: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
              onChanged: onSlotChanged,
              items: _kTimeSlots
                  .map(
                    (slot) => DropdownMenuItem(
                      value: slot,
                      child: Text(
                        slot,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Özel istek veya adres tarifi...',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PaymentSection
// ---------------------------------------------------------------------------
class _PaymentSection extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentSection({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Yöntemi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _PaymentOption(
            label: 'Kapıda Nakit',
            icon: Icons.payments_outlined,
            isSelected: selected == PaymentMethod.cash,
            isDisabled: false,
            onTap: () => onChanged(PaymentMethod.cash),
          ),
          const SizedBox(height: 8),
          _PaymentOption(
            label: 'Kredi/Banka Kartı',
            icon: Icons.credit_card_outlined,
            isSelected: selected == PaymentMethod.cardOnDelivery,
            isDisabled: true,
            badgeText: 'Yakında',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final String? badgeText;
  final VoidCallback? onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = isSelected && !isDisabled;
    final borderColor = isActive
        ? AppColors.secondary
        : AppColors.border;
    final borderWidth = isActive ? 1.5 : 1.0;
    final bgColor =
        isActive ? AppColors.secondary.withAlpha(13) : AppColors.surface;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            // Manuel radio circle
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? AppColors.secondary
                      : AppColors.border,
                  width: 2,
                ),
                color: isActive ? AppColors.secondary : AppColors.surface,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 20,
              color: isDisabled ? AppColors.textHint : AppColors.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDisabled
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (badgeText != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BottomOrderBar
// ---------------------------------------------------------------------------
class _BottomOrderBar extends StatelessWidget {
  final double total;
  final int selectedCount;
  final bool isLoading;
  final VoidCallback onConfirm;

  const _BottomOrderBar({
    required this.total,
    required this.selectedCount,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = selectedCount > 0 && !isLoading;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedCount > 0
                    ? '$selectedCount ürün çeşidi'
                    : 'Ürün seçilmedi',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Toplam: ${total.toStringAsFixed(2)} TL',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isEnabled ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled
                    ? AppColors.primary
                    : AppColors.primary.withAlpha(102),
                foregroundColor: AppColors.textWhite,
                disabledBackgroundColor: AppColors.primary.withAlpha(102),
                disabledForegroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.textWhite,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Siparişi Onayla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShimmerRow — loading placeholder
// ---------------------------------------------------------------------------
class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.imageBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GuestInfoForm -- misafir müşteri için ad, telefon, adres girişi
// ---------------------------------------------------------------------------

class _GuestInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  const _GuestInfoForm({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Misafir Müşteri Bilgileri',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Ad Soyad',
              prefixIcon: const Icon(Icons.person_outline,
                  size: 18, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Telefon (05XX XXX XX XX)',
              prefixIcon: const Icon(Icons.phone_outlined,
                  size: 18, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: addressController,
            textInputAction: TextInputAction.done,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Teslimat adresi (cadde, mahalle, daire...)',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.textHint),
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
