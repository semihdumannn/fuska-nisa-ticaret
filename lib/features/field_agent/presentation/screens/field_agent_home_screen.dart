import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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
// Ana ekran — ConsumerStatefulWidget (form state + lifecycle gerekiyor)
// ---------------------------------------------------------------------------
class FieldAgentHomeScreen extends ConsumerStatefulWidget {
  const FieldAgentHomeScreen({super.key});

  @override
  ConsumerState<FieldAgentHomeScreen> createState() =>
      _FieldAgentHomeScreenState();
}

class _FieldAgentHomeScreenState extends ConsumerState<FieldAgentHomeScreen> {
  // Form controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Hızlı sipariş form state
  ProductModel? _selectedProduct;
  int _qty = 1;
  bool _isCreatingOrder = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Sipariş oluştur
  // ---------------------------------------------------------------------------
  Future<void> _createOrder(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      _showSnackBar('Lütfen bir ürün seçin.', isError: true);
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      final now = DateTime.now();
      final unitPrice = _selectedProduct!.effectivePrice;
      final totalPrice = unitPrice * _qty;

      // customerId: saha terminali misafir siparişi — createdBy agent uid,
      // customerId müşteri için ayrı uid olmalı; misafir siparişinde agent uid kullanılır.
      final customerName = _customerNameController.text.trim();
      final customerPhone = _customerPhoneController.text.trim();
      final order = OrderModel(
        id: '',
        orderNo: '',
        customerId: 'guest_${user.uid}', // misafir — müşteri uid'i yok
        customerName: customerName,
        customerPhone: customerPhone,
        source: OrderSource.fieldAgent,
        createdBy: user.uid,
        status: OrderStatus.pending,
        statusHistory: [
          StatusHistory(
            status: OrderStatus.pending,
            timestamp: now,
            by: user.uid,
          ),
        ],
        items: [
          OrderItem(
            productId: _selectedProduct!.id,
            productName: _selectedProduct!.name,
            qty: _qty,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
          ),
        ],
        deliveryAddress: const DeliveryAddress(
          fullAddress: 'Saha terminali',
          district: '-',
          city: '-',
        ),
        paymentMethod: PaymentMethod.cash,
        subtotal: totalPrice,
        discount: 0,
        total: totalPrice,
        createdAt: now,
        updatedAt: now,
      );

      final orderNo =
          await ref.read(orderRepositoryProvider).createOrder(order);

      if (!mounted) return;

      _clearForm();
      _showSnackBar('Sipariş oluşturuldu: #$orderNo');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Sipariş oluşturulamadı. Tekrar deneyin.', isError: true);
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    setState(() {
      _selectedProduct = null;
      _qty = 1;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Oturum bulunamadı.'));
            }
            return isTablet
                ? _TabletLayout(
                    user: user,
                    formKey: _formKey,
                    customerNameController: _customerNameController,
                    customerPhoneController: _customerPhoneController,
                    selectedProduct: _selectedProduct,
                    qty: _qty,
                    isCreatingOrder: _isCreatingOrder,
                    onProductChanged: (p) =>
                        setState(() => _selectedProduct = p),
                    onQtyChanged: (q) => setState(() => _qty = q),
                    onCreateOrder: () => _createOrder(user),
                    onLogout: () =>
                        ref.read(authNotifierProvider.notifier).signOut(),
                  )
                : _PhoneLayout(
                    user: user,
                    formKey: _formKey,
                    customerNameController: _customerNameController,
                    customerPhoneController: _customerPhoneController,
                    selectedProduct: _selectedProduct,
                    qty: _qty,
                    isCreatingOrder: _isCreatingOrder,
                    onProductChanged: (p) =>
                        setState(() => _selectedProduct = p),
                    onQtyChanged: (q) => setState(() => _qty = q),
                    onCreateOrder: () => _createOrder(user),
                    onLogout: () =>
                        ref.read(authNotifierProvider.notifier).signOut(),
                  );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Telefon layout — tek kolon
// ---------------------------------------------------------------------------
class _PhoneLayout extends StatelessWidget {
  final UserModel user;
  final GlobalKey<FormState> formKey;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final ProductModel? selectedProduct;
  final int qty;
  final bool isCreatingOrder;
  final ValueChanged<ProductModel?> onProductChanged;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onCreateOrder;
  final VoidCallback onLogout;

  const _PhoneLayout({
    required this.user,
    required this.formKey,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.selectedProduct,
    required this.qty,
    required this.isCreatingOrder,
    required this.onProductChanged,
    required this.onQtyChanged,
    required this.onCreateOrder,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(user: user, onLogout: onLogout),
          const SizedBox(height: 16),
          _StatsGrid(),
          const SizedBox(height: 20),
          _QuickOrderForm(
            formKey: formKey,
            customerNameController: customerNameController,
            customerPhoneController: customerPhoneController,
            selectedProduct: selectedProduct,
            qty: qty,
            isCreatingOrder: isCreatingOrder,
            onProductChanged: onProductChanged,
            onQtyChanged: onQtyChanged,
            onCreateOrder: onCreateOrder,
          ),
          const SizedBox(height: 20),
          _TodayOrdersSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet layout — iki kolon
// ---------------------------------------------------------------------------
class _TabletLayout extends StatelessWidget {
  final UserModel user;
  final GlobalKey<FormState> formKey;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final ProductModel? selectedProduct;
  final int qty;
  final bool isCreatingOrder;
  final ValueChanged<ProductModel?> onProductChanged;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onCreateOrder;
  final VoidCallback onLogout;

  const _TabletLayout({
    required this.user,
    required this.formKey,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.selectedProduct,
    required this.qty,
    required this.isCreatingOrder,
    required this.onProductChanged,
    required this.onQtyChanged,
    required this.onCreateOrder,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol kolon: header + stats + form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(user: user, onLogout: onLogout),
                const SizedBox(height: 16),
                _StatsGrid(columns: 4),
                const SizedBox(height: 20),
                _QuickOrderForm(
                  formKey: formKey,
                  customerNameController: customerNameController,
                  customerPhoneController: customerPhoneController,
                  selectedProduct: selectedProduct,
                  qty: qty,
                  isCreatingOrder: isCreatingOrder,
                  onProductChanged: onProductChanged,
                  onQtyChanged: onQtyChanged,
                  onCreateOrder: onCreateOrder,
                ),
              ],
            ),
          ),
        ),
        // Sag kolon: bugünkü siparişler
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 24),
            child: _TodayOrdersSection(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header card — kullanıcı bilgisi + tarih + logout
// ---------------------------------------------------------------------------
class _HeaderCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const _HeaderCard({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMM yyyy', 'tr_TR').format(DateTime.now());
    final initials = user.name.isNotEmpty
        ? user.name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ad + rol badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role == UserRole.fieldAgent
                        ? 'Saha Ekibi'
                        : user.role.displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tarih + butonlar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                today,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.productList),
                    icon: const Icon(Icons.storefront_outlined,
                        color: AppColors.accent, size: 22),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    tooltip: 'Müşteri Görünümü',
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 22),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats grid — 2x2 telefon, 4 kolon tablet
// ---------------------------------------------------------------------------
class _StatsGrid extends ConsumerWidget {
  final int columns;
  const _StatsGrid({this.columns = 2});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeOrdersProvider);

    return ordersAsync.when(
      loading: () => _buildShimmerGrid(columns),
      error: (_, __) => _buildErrorGrid(columns),
      data: (orders) {
        final total = orders.length;
        final pending = orders
            .where((o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.confirmed)
            .length;
        final preparing =
            orders.where((o) => o.status == OrderStatus.preparing).length;
        final onTheWay =
            orders.where((o) => o.status == OrderStatus.onTheWay).length;

        final stats = [
          _StatData(
            label: 'Toplam Sipariş',
            value: '$total',
            icon: Icons.receipt_long,
            color: AppColors.primary,
          ),
          _StatData(
            label: 'Bekleyen',
            value: '$pending',
            icon: Icons.hourglass_empty,
            color: AppColors.warning,
          ),
          _StatData(
            label: 'Hazırlanıyor',
            value: '$preparing',
            icon: Icons.inventory_2_outlined,
            color: AppColors.accent,
          ),
          _StatData(
            label: 'Yolda',
            value: '$onTheWay',
            icon: Icons.local_shipping_outlined,
            color: AppColors.secondary,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: stats.length,
          itemBuilder: (context, i) => _StatCard(stat: stats[i]),
        );
      },
    );
  }

  Widget _buildShimmerGrid(int columns) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surface,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorGrid(int columns) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: const Text(
        'İstatistikler yüklenemedi',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stat.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, color: stat.color, size: 22),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: stat.color,
                fontFamily: 'Poppins',
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hızlı sipariş formu
// ---------------------------------------------------------------------------
class _QuickOrderForm extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final ProductModel? selectedProduct;
  final int qty;
  final bool isCreatingOrder;
  final ValueChanged<ProductModel?> onProductChanged;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onCreateOrder;

  const _QuickOrderForm({
    required this.formKey,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.selectedProduct,
    required this.qty,
    required this.isCreatingOrder,
    required this.onProductChanged,
    required this.onQtyChanged,
    required this.onCreateOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            const Text(
              'Hızlı Sipariş',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 14),

            // Müşteri adı
            TextFormField(
              controller: customerNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                hintText: 'Müşteri adı girin',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Müşteri adı zorunlu' : null,
            ),
            const SizedBox(height: 12),

            // Telefon (opsiyonel)
            TextFormField(
              controller: customerPhoneController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Telefon (opsiyonel)',
                hintText: '05xx xxx xx xx',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Ürün seçimi
            productsAsync.when(
              loading: () => _ProductDropdownShimmer(),
              error: (_, __) => const _ProductDropdownError(),
              data: (products) {
                final inStockProducts =
                    products.where((p) => p.inStock).toList();
                return FormField<ProductModel>(
                  initialValue: selectedProduct,
                  validator: (v) => v == null ? 'Ürün seçiniz' : null,
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ürün Seç',
                            prefixIcon: const Icon(
                              Icons.inventory_outlined,
                              size: 20,
                            ),
                            errorText: field.errorText,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.error, width: 2),
                            ),
                          ),
                          child: DropdownButton<ProductModel>(
                            value: selectedProduct,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            hint: const Text(
                              'Ürün seçin',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            items: inStockProducts
                                .map(
                                  (p) => DropdownMenuItem<ProductModel>(
                                    value: p,
                                    child: Text(
                                      '${p.name} — ${p.effectivePrice.toStringAsFixed(2)}₺',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (p) {
                              onProductChanged(p);
                              field.didChange(p);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // Miktar
            _QtySelector(qty: qty, onChanged: onQtyChanged),
            const SizedBox(height: 16),

            // Sipariş oluştur butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isCreatingOrder ? null : onCreateOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCreatingOrder
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Sipariş Oluştur',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ürün dropdown shimmer
class _ProductDropdownShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Ürün dropdown hata
class _ProductDropdownError extends StatelessWidget {
  const _ProductDropdownError();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Ürünler yüklenemedi',
        style: TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}

// Miktar seçici
class _QtySelector extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;

  const _QtySelector({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Miktar',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.secondary, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: qty > 1 ? () => onChanged(qty - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: qty < 99 ? () => onChanged(qty + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
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

// ---------------------------------------------------------------------------
// Bugünkü siparişler bölümü
// ---------------------------------------------------------------------------
class _TodayOrdersSection extends ConsumerWidget {
  const _TodayOrdersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bugünkü Siparişler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.orderManagement),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(48, 36),
              ),
              child: const Text(
                'Tümü',
                style: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ordersAsync.when(
          loading: () => _buildShimmerList(),
          error: (e, _) => _TodayOrdersError(onRetry: () => ref.refresh(activeOrdersProvider)),
          data: (orders) {
            final today = DateTime.now();
            final todaysOrders = orders
                .where((o) =>
                    o.createdAt.day == today.day &&
                    o.createdAt.month == today.month &&
                    o.createdAt.year == today.year)
                .toList();

            if (todaysOrders.isEmpty) {
              return _TodayOrdersEmpty();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todaysOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _OrderCard(order: todaysOrders[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Shimmer.fromColors(
            baseColor: AppColors.border,
            highlightColor: AppColors.surface,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Hata durumu
class _TodayOrdersError extends StatelessWidget {
  final VoidCallback onRetry;
  const _TodayOrdersError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Siparişler yüklenemedi',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tekrar Dene'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// Boş durum
class _TodayOrdersEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textHint),
          SizedBox(height: 10),
          Text(
            'Bugün sipariş yok',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sipariş kartı
// ---------------------------------------------------------------------------
class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.onTheWay:
        return AppColors.statusOnTheWay;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  bool get _canConfirm =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.confirmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(order.status);

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.orderDetail.replaceFirst(':id', order.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Ana satır
            Row(
              children: [
                // Sol ikon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.receipt_long,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                // Orta: no + isim + ürün sayısı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNo}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${order.totalItems} ürün',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                // Sag: fiyat + durum badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${order.total.toStringAsFixed(2)}₺',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Alt buton satırı
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Detay Gör
                OutlinedButton(
                  onPressed: () => context.push(
                    AppRoutes.orderDetail.replaceFirst(':id', order.id),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.border, width: 1),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  child: const Text('Detay Gör'),
                ),
                if (_canConfirm) ...[
                  const SizedBox(width: 8),
                  // Onayla
                  ElevatedButton(
                    onPressed: () => _confirmOrder(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    child: const Text('Onayla'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            newStatus: OrderStatus.confirmed,
            updatedBy: user.uid,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sipariş onaylandı.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('İşlem başarısız. Tekrar deneyin.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
