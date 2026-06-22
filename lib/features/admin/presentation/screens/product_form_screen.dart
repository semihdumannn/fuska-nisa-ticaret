import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_picker_widget.dart';
import '../../../../features/products/data/repositories/category_repository.dart';
import '../../data/repositories/admin_variant_repository.dart';
import '../providers/admin_products_provider.dart';
import '../widgets/admin_sidebar.dart';

const double _kDesktopBreakpoint = 1024.0;

// ---------------------------------------------------------------------------
// _VariantEntry — tek bir varyant icin controller + meta tutar
// ---------------------------------------------------------------------------
class _VariantEntry {
  String? firestoreId;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController salePriceCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController packageQtyCtrl;
  bool isKoli;

  _VariantEntry({
    this.firestoreId,
    required String name,
    double price = 0,
    double salePrice = 0,
    int stock = 0,
    int packageQty = 0,
    this.isKoli = false,
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(
            text: price > 0 ? price.toStringAsFixed(2) : ''),
        salePriceCtrl = TextEditingController(
            text: salePrice > 0 ? salePrice.toStringAsFixed(2) : ''),
        stockCtrl =
            TextEditingController(text: stock > 0 ? stock.toString() : ''),
        packageQtyCtrl = TextEditingController(
            text: packageQty > 0 ? packageQty.toString() : '');

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    salePriceCtrl.dispose();
    stockCtrl.dispose();
    packageQtyCtrl.dispose();
  }
}

// ---------------------------------------------------------------------------
// ProductFormScreen — yeni urun / urun duzenle
// ---------------------------------------------------------------------------
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<_VariantEntry> _variants = [];

  List<String> _selectedCategoryIds = [];
  bool _isActive = true;
  String? _imageUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    } else {
      _variants = [_VariantEntry(name: 'Adet')];
    }
  }

  void _loadProduct() {
    final products = ref.read(adminProductsProvider).value ?? [];
    // ApiProductModel.id is int; widget.productId is String — parse to compare
    final productIdInt = int.tryParse(widget.productId ?? '');
    final product = products.where((p) => p.id == productIdInt).firstOrNull;
    if (product == null) return;

    _nameCtrl.text = product.name;
    _descCtrl.text = product.description ?? '';
    setState(() {
      _selectedCategoryIds =
          product.categoryIds.map((id) => id.toString()).toList();
      _isActive = product.isActive;
      _imageUrl = product.imageUrl;
    });

    _loadVariants();
  }

  Future<void> _loadVariants() async {
    final repo = ref.read(adminVariantRepositoryProvider);
    final rawList =
        await repo.getVariantsByProduct(widget.productId!);

    if (!mounted) return;

    final loaded = rawList.map((data) {
      return _VariantEntry(
        firestoreId: data['_firestoreId'] as String?,
        name: data['name'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0,
        stock: (data['stock'] as num?)?.toInt() ?? 0,
        packageQty: (data['packageQty'] as num?)?.toInt() ?? 0,
        isKoli: (data['unit'] as String?) == 'koli',
      );
    }).toList();

    setState(() {
      _variants = loaded.isEmpty ? [_VariantEntry(name: 'Adet')] : loaded;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Kaydet — tek atomik batch
  // -------------------------------------------------------------------------
  Future<void> _save() async {
    setState(() => _isSaving = true);
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'En az bir kategori secin.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final variantRepo = ref.read(adminVariantRepositoryProvider);

      // 1. Yeni varyantlara client-side ID ata
      for (final entry in _variants) {
        if (entry.firestoreId == null &&
            entry.nameCtrl.text.trim().isNotEmpty) {
          entry.firestoreId = variantRepo.allocateVariantId();
        }
      }

      final validEntries = _variants
          .where((v) =>
              v.nameCtrl.text.trim().isNotEmpty && v.firestoreId != null)
          .toList();

      // 2. Koli / Primary belirle — explicit toggle'a gore
      _VariantEntry? koliEntry;
      _VariantEntry? primaryEntry;
      for (final entry in validEntries) {
        if (entry.isKoli && koliEntry == null) {
          koliEntry = entry;
        } else if (!entry.isKoli && primaryEntry == null) {
          primaryEntry = entry;
        }
      }
      // Fallback: koli secilmemisse ilk entry primary
      primaryEntry ??= validEntries.isNotEmpty ? validEntries.first : null;

      // 3. Denormalized degerleri hesapla
      double? calcPrice(String t) {
        final v = double.tryParse(t);
        return (v != null && v > 0) ? v : null;
      }

      double? calcSalePrice(String t, double? base) {
        final v = double.tryParse(t);
        if (v == null || v <= 0) return null;
        if (base != null && v >= base) return null;
        return v;
      }

      final primaryPrice =
          calcPrice(primaryEntry?.priceCtrl.text ?? '');
      final primarySalePrice =
          calcSalePrice(primaryEntry?.salePriceCtrl.text ?? '', primaryPrice);
      final primaryStock = primaryEntry != null
          ? (int.tryParse(primaryEntry.stockCtrl.text) ?? 0)
          : 0;

      final koliVariantId = koliEntry?.firestoreId;
      final koliPrice = calcPrice(koliEntry?.priceCtrl.text ?? '');
      final koliSalePrice =
          calcSalePrice(koliEntry?.salePriceCtrl.text ?? '', koliPrice);
      final koliStock = koliEntry != null
          ? (int.tryParse(koliEntry.stockCtrl.text) ?? 0)
          : 0;
      final koliPackageQty = koliEntry != null
          ? (int.tryParse(koliEntry.packageQtyCtrl.text) ?? 0)
          : 0;

      // 4. Urun ID'si
      final productDocId =
          _isEditing ? widget.productId! : const Uuid().v4();

      // 5. Mevcut varyantlari al (silinecekleri belirlemek icin)
      final existingRaw =
          await variantRepo.getVariantsByProduct(productDocId);
      final keepIds = validEntries.map((v) => v.firestoreId!).toSet();
      final existingVarIds =
          existingRaw.map((m) => m['_firestoreId'] as String).toSet();
      final idsToDelete = existingVarIds.difference(keepIds).toList();

      // 6. Urun dokumani — tum alanlar + denormalized
      final productData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'categoryIds': _selectedCategoryIds,
        'categoryId': _selectedCategoryIds.isNotEmpty
            ? _selectedCategoryIds.first
            : '',
        'imageUrl': _imageUrl,
        'imageUrls': _imageUrl != null ? [_imageUrl!] : <String>[],
        'isActive': _isActive,
        'updatedAt': DateTime.now().toIso8601String(),
        // Denormalized — urun kartinda N+1 okuma olmadan gosterilir
        'price': primaryPrice,
        'salePrice': primarySalePrice,
        'stock': primaryStock,
        'koliVariantId': koliVariantId,
        'koliPrice': koliPrice,
        'koliSalePrice': koliSalePrice,
        'koliStock': koliStock,
        'koliPackageQty': koliPackageQty > 0 ? koliPackageQty : null,
      };

      if (!_isEditing) {
        // Yeni urun: ek sabit alanlar eklenir
        productData.addAll({
          'isFeatured': false,
          'order': 0,
          'brandId': '',
          'tags': <String>[],
        });
      }

      // 7. Varyant yazma entry'leri oluştur
      final variantWriteEntries = validEntries.map((entry) {
        final price = double.tryParse(entry.priceCtrl.text) ?? 0.0;
        final sp = double.tryParse(entry.salePriceCtrl.text);
        final validSp = (sp != null && sp > 0 && sp < price) ? sp : null;
        final pqty = int.tryParse(entry.packageQtyCtrl.text) ?? 0;

        return VariantWriteEntry(
          firestoreId: entry.firestoreId!,
          isExisting: existingVarIds.contains(entry.firestoreId),
          data: {
            'productId': productDocId,
            'name': entry.nameCtrl.text.trim(),
            'price': price,
            'salePrice': validSp,
            'stock': int.tryParse(entry.stockCtrl.text) ?? 0,
            'unit': entry.isKoli ? 'koli' : 'adet',
            'packageQty': pqty > 0 ? pqty : null,
            'isActive': true,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }).toList();

      // 8. Repository üzerinden atomik batch commit
      await variantRepo.saveProductWithVariants(
        productDocId: productDocId,
        productData: productData,
        isNewProduct: !_isEditing,
        variantEntries: variantWriteEntries,
        variantIdsToDelete: idsToDelete,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Urun kaydedildi.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hata: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add(_VariantEntry(name: ''));
    });
  }

  void _removeVariant(int index) {
    if (_variants.length <= 1) return;
    final entry = _variants[index];
    setState(() {
      _variants.removeAt(index);
    });
    entry.dispose();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    final title = _isEditing ? 'Ürünü Düzenle' : 'Yeni Ürün';

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.adminBackground,
        body: Row(
          children: [
            const AdminSidebar(),
            Expanded(
              child: _FormContent(
                formKey: _formKey,
                isDesktop: true,
                title: title,
                nameCtrl: _nameCtrl,
                descCtrl: _descCtrl,
                selectedCategoryIds: _selectedCategoryIds,
                isActive: _isActive,
                imageUrl: _imageUrl,
                isSaving: _isSaving,
                variants: _variants,
                onCategoryIdsChanged: (ids) =>
                    setState(() => _selectedCategoryIds = ids),
                onActiveChanged: (v) => setState(() => _isActive = v),
                onImageUploaded: (url) => setState(() => _imageUrl = url),
                onSave: _save,
                onCancel: () => context.pop(),
                onAddVariant: _addVariant,
                onRemoveVariant: _removeVariant,
                onVariantChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        elevation: 0,
      ),
      body: _FormContent(
        formKey: _formKey,
        isDesktop: false,
        title: title,
        nameCtrl: _nameCtrl,
        descCtrl: _descCtrl,
        selectedCategoryIds: _selectedCategoryIds,
        isActive: _isActive,
        imageUrl: _imageUrl,
        isSaving: _isSaving,
        variants: _variants,
        onCategoryIdsChanged: (ids) =>
            setState(() => _selectedCategoryIds = ids),
        onActiveChanged: (v) => setState(() => _isActive = v),
        onImageUploaded: (url) => setState(() => _imageUrl = url),
        onSave: _save,
        onCancel: () => context.pop(),
        onAddVariant: _addVariant,
        onRemoveVariant: _removeVariant,
        onVariantChanged: () => setState(() {}),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FormContent — form icerigi
// ---------------------------------------------------------------------------
class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.formKey,
    required this.isDesktop,
    required this.title,
    required this.nameCtrl,
    required this.descCtrl,
    required this.selectedCategoryIds,
    required this.isActive,
    required this.imageUrl,
    required this.isSaving,
    required this.variants,
    required this.onCategoryIdsChanged,
    required this.onActiveChanged,
    required this.onImageUploaded,
    required this.onSave,
    required this.onCancel,
    required this.onAddVariant,
    required this.onRemoveVariant,
    required this.onVariantChanged,
  });

  final GlobalKey<FormState> formKey;
  final bool isDesktop;
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final List<String> selectedCategoryIds;
  final bool isActive;
  final String? imageUrl;
  final bool isSaving;
  final List<_VariantEntry> variants;
  final ValueChanged<List<String>> onCategoryIdsChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<String> onImageUploaded;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onAddVariant;
  final void Function(int index) onRemoveVariant;
  final VoidCallback onVariantChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),
            ],
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LeftColumn(
                        imageUrl: imageUrl,
                        isActive: isActive,
                        onImageUploaded: onImageUploaded,
                        onActiveChanged: onActiveChanged,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _RightColumn(
                          nameCtrl: nameCtrl,
                          descCtrl: descCtrl,
                          selectedCategoryIds: selectedCategoryIds,
                          variants: variants,
                          onCategoryIdsChanged: onCategoryIdsChanged,
                          onAddVariant: onAddVariant,
                          onRemoveVariant: onRemoveVariant,
                          onVariantChanged: onVariantChanged,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Center(
                        child: ImagePickerWidget(
                          initialImageUrl: imageUrl,
                          onImageUploaded: onImageUploaded,
                          size: 200,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActiveToggle(
                          isActive: isActive, onChanged: onActiveChanged),
                      const SizedBox(height: 24),
                      _RightColumn(
                        nameCtrl: nameCtrl,
                        descCtrl: descCtrl,
                        selectedCategoryIds: selectedCategoryIds,
                        variants: variants,
                        onCategoryIdsChanged: onCategoryIdsChanged,
                        onAddVariant: onAddVariant,
                        onRemoveVariant: onRemoveVariant,
                        onVariantChanged: onVariantChanged,
                      ),
                    ],
                  ),
            const SizedBox(height: 32),
            _FormActions(
              isSaving: isSaving,
              onSave: onSave,
              onCancel: onCancel,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LeftColumn — gorsel + aktif toggle
// ---------------------------------------------------------------------------
class _LeftColumn extends StatelessWidget {
  const _LeftColumn({
    required this.imageUrl,
    required this.isActive,
    required this.onImageUploaded,
    required this.onActiveChanged,
  });

  final String? imageUrl;
  final bool isActive;
  final ValueChanged<String> onImageUploaded;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          ImagePickerWidget(
            initialImageUrl: imageUrl,
            onImageUploaded: onImageUploaded,
            size: 300,
          ),
          const SizedBox(height: 20),
          _ActiveToggle(isActive: isActive, onChanged: onActiveChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ActiveToggle
// ---------------------------------------------------------------------------
class _ActiveToggle extends StatelessWidget {
  const _ActiveToggle({required this.isActive, required this.onChanged});

  final bool isActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urun Durumu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Aktif ürünler müşteri uygulamasinda görünür',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RightColumn — form alanlari
// ---------------------------------------------------------------------------
class _RightColumn extends ConsumerWidget {
  const _RightColumn({
    required this.nameCtrl,
    required this.descCtrl,
    required this.selectedCategoryIds,
    required this.variants,
    required this.onCategoryIdsChanged,
    required this.onAddVariant,
    required this.onRemoveVariant,
    required this.onVariantChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final List<String> selectedCategoryIds;
  final List<_VariantEntry> variants;
  final ValueChanged<List<String>> onCategoryIdsChanged;
  final VoidCallback onAddVariant;
  final void Function(int index) onRemoveVariant;
  final VoidCallback onVariantChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urun Bilgileri
        _FormSection(
          title: 'Urun Bilgileri',
          children: [
            const _FormLabel(text: 'Urun Adi *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: nameCtrl,
              maxLength: 100,
              style: _inputStyle,
              decoration: _inputDecoration(hint: 'Ornek: Damacana Su 19L'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Urun adi zorunludur';
                if (v.trim().length < 2) return 'En az 2 karakter olmali';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const _FormLabel(text: 'Aciklama'),
            const SizedBox(height: 6),
            TextFormField(
              controller: descCtrl,
              maxLength: 500,
              maxLines: 3,
              style: _inputStyle,
              decoration:
                  _inputDecoration(hint: 'Urun hakkinda kisa aciklama...'),
            ),
            const SizedBox(height: 16),
            const _FormLabel(text: 'Kategoriler *'),
            const SizedBox(height: 6),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text(
                'Kategoriler yüklenemedi',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
              data: (categories) {
                final rootCats =
                    categories.where((c) => c.isRoot && c.isActive).toList();
                if (rootCats.isEmpty) {
                  return const Text(
                    'Henuz kategori yok.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Secili kategoriler — silinebilir chip'ler
                    if (selectedCategoryIds.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedCategoryIds.map((id) {
                          final cat =
                              rootCats.where((c) => c.id == id).firstOrNull;
                          return Chip(
                            label: Text(
                              cat?.name ?? id,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                color: AppColors.textWhite,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            deleteIconColor:
                                AppColors.textWhite.withValues(alpha: 0.8),
                            onDeleted: () {
                              final updated =
                                  List<String>.from(selectedCategoryIds)
                                    ..remove(id);
                              onCategoryIdsChanged(updated);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Secilmemis kategoriler — eklenebilir ActionChip'ler
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: rootCats
                          .where((c) => !selectedCategoryIds.contains(c.id))
                          .map(
                            (cat) => ActionChip(
                              label: Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              avatar: const Icon(
                                Icons.add,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              onPressed: () {
                                final updated =
                                    List<String>.from(selectedCategoryIds)
                                      ..add(cat.id);
                                onCategoryIdsChanged(updated);
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          )
                          .toList(),
                    ),
                    // Validation hint
                    if (selectedCategoryIds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'En az bir kategori secin',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Varyantlar
        _VariantsSection(
          variants: variants,
          onAddVariant: onAddVariant,
          onRemoveVariant: onRemoveVariant,
          onVariantChanged: onVariantChanged,
        ),
      ],
    );
  }

  static const TextStyle _inputStyle = TextStyle(
    fontSize: 14,
    fontFamily: 'Poppins',
    color: AppColors.textPrimary,
  );

  static InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        fontFamily: 'Poppins',
        color: AppColors.textHint,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
  }
}

// ---------------------------------------------------------------------------
// _VariantsSection — dinamik varyant listesi
// ---------------------------------------------------------------------------
class _VariantsSection extends StatelessWidget {
  const _VariantsSection({
    required this.variants,
    required this.onAddVariant,
    required this.onRemoveVariant,
    required this.onVariantChanged,
  });

  final List<_VariantEntry> variants;
  final VoidCallback onAddVariant;
  final void Function(int index) onRemoveVariant;
  final VoidCallback onVariantChanged;

  static const TextStyle _inputStyle = TextStyle(
    fontSize: 14,
    fontFamily: 'Poppins',
    color: AppColors.textPrimary,
  );

  static InputDecoration _inputDecoration({
    required String hint,
    String? prefix,
    String? suffix,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        fontFamily: 'Poppins',
        color: AppColors.textHint,
      ),
      prefixText: prefix,
      prefixStyle: const TextStyle(
          color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 13),
      suffixText: suffix,
      suffixStyle: const TextStyle(
          color: AppColors.textSecondary, fontFamily: 'Poppins', fontSize: 13),
      prefixIcon: prefixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baslik satiri
          Row(
            children: [
              const Text(
                'Varyantlar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.primary),
                tooltip: 'Varyant Ekle',
                onPressed: onAddVariant,
              ),
            ],
          ),
          const Divider(height: 20),

          // Varyant kartlari
          ...List.generate(variants.length, (index) {
            final entry = variants[index];
            final isOnlyOne = variants.length == 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _VariantCard(
                entry: entry,
                isOnlyOne: isOnlyOne,
                index: index,
                inputStyle: _inputStyle,
                inputDecoration: _inputDecoration,
                onRemove: onRemoveVariant,
                onChanged: onVariantChanged,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VariantCard — tek bir varyant karti (StatefulWidget — isKoli toggle icin)
// ---------------------------------------------------------------------------
class _VariantCard extends StatefulWidget {
  const _VariantCard({
    required this.entry,
    required this.isOnlyOne,
    required this.index,
    required this.inputStyle,
    required this.inputDecoration,
    required this.onRemove,
    required this.onChanged,
  });

  final _VariantEntry entry;
  final bool isOnlyOne;
  final int index;
  final TextStyle inputStyle;
  final InputDecoration Function({
    required String hint,
    String? prefix,
    String? suffix,
    Widget? prefixIcon,
  }) inputDecoration;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  @override
  State<_VariantCard> createState() => _VariantCardState();
}

class _VariantCardState extends State<_VariantCard> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Satir 1: Varyant adi + Sil
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.nameCtrl,
                  style: widget.inputStyle,
                  decoration: widget.inputDecoration(
                      hint: 'Varyant adi (ornek: Adet, Koli)'),
                  onChanged: (_) => widget.onChanged(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Varyant adi zorunlu';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: widget.isOnlyOne
                      ? AppColors.textHint
                      : AppColors.error,
                ),
                tooltip: widget.isOnlyOne
                    ? 'Son varyant silinemez'
                    : 'Varyanti Sil',
                onPressed: widget.isOnlyOne
                    ? null
                    : () => widget.onRemove(widget.index),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Satir 2: Fiyat | Indirimli Fiyat | Stok
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fiyat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel(text: 'Fiyat (TL) *'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: entry.priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: widget.inputStyle,
                      decoration: widget.inputDecoration(
                          hint: '0.00', prefix: 'TL '),
                      onChanged: (_) => widget.onChanged(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Fiyat zorunlu';
                        }
                        final p = double.tryParse(v);
                        if (p == null || p <= 0) return 'Gecerli deger';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Indirimli Fiyat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel(text: 'Indirimli (TL)'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: entry.salePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: widget.inputStyle,
                      decoration: widget.inputDecoration(
                          hint: '0.00', prefix: 'TL '),
                      onChanged: (_) => widget.onChanged(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final sale = double.tryParse(v);
                        final price =
                            double.tryParse(entry.priceCtrl.text);
                        if (sale == null || sale < 0) {
                          return 'Gecerli deger';
                        }
                        if (price != null && sale >= price) {
                          return 'Fiyattan kucuk olmali';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stok
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel(text: 'Stok *'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: entry.stockCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: widget.inputStyle,
                      decoration: widget.inputDecoration(hint: '0'),
                      onChanged: (_) => widget.onChanged(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Stok zorunlu';
                        }
                        final p = int.tryParse(v);
                        if (p == null || p < 0) return 'Gecerli deger';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Koli Varianti toggle
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: entry.isKoli
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: entry.isKoli ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Koli Varyanti',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.isKoli
                            ? 'Bu varyant koli birimi olarak isaretlendi'
                            : 'Koli biriminde paketlenmiş varyant',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: entry.isKoli,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => entry.isKoli = v);
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ),

          // Koli icerigi alani — sadece isKoli=true ise goster
          if (entry.isKoli) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.packageQtyCtrl,
              decoration: widget.inputDecoration(
                hint: 'Ornek: 6',
                prefixIcon: const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ).copyWith(labelText: '1 Koli = ? Adet'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => widget.onChanged(),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FormSection — başlık + içerik kart
// ---------------------------------------------------------------------------
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontFamily: 'Poppins',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FormActions — iptal + kaydet butonlari
// ---------------------------------------------------------------------------
class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isSaving ? null : onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          child: const Text('İptal'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isSaving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textWhite,
                  ),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
