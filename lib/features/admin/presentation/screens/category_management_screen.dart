import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/network/api_endpoints.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/admin/data/repositories/admin_category_repository.dart';
import 'package:nisa_ticaret/features/admin/presentation/widgets/admin_sidebar.dart';
import 'package:nisa_ticaret/features/products/data/models/api_category_model.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';

const double _kDesktopBreakpoint = 1024.0;

// ---------------------------------------------------------------------------
// API'den kategori listesini çeken provider — GET /v1/categories
// ---------------------------------------------------------------------------
final _apiCategoriesProvider =
    FutureProvider<List<ApiCategoryModel>>((ref) async {
  final dio = ref.read(apiClientProvider).dio;
  try {
    final response = await dio.get(ApiEndpoints.categories);
    final body = response.data;
    List<dynamic> rawList = [];
    if (body is List) {
      rawList = body;
    } else if (body is Map && body['data'] is List) {
      rawList = body['data'] as List;
    }
    return rawList
        .map((j) => ApiCategoryModel.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  } on DioException {
    return [];
  }
});

// ─────────────────────────────────────────────
// Preset renk paleti (Fuska Design System)
// ─────────────────────────────────────────────
const _kPresetColors = [
  AppColors.accent, // Turkuaz
  AppColors.primary, // Pembe (primary)
  AppColors.secondary, // Lacivert (secondary)
  AppColors.categoryOrange, // Turuncu
  AppColors.success, // Yesil
  AppColors.categoryPurple, // Mor
];

const _kPresetColorHex = [
  '#00A6AB',
  '#E73A99',
  '#13275A',
  '#FF7043',
  '#43A047',
  '#7B1FA2',
];

/// Hex renk string'ini Color'a donusturur (#RRGGBB veya RRGGBB).
Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return AppColors.black;
}

// ─────────────────────────────────────────────
// Ana Ekran
// ─────────────────────────────────────────────
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _kDesktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.adminBackground,
        body: Row(
          children: [
            const AdminSidebar(),
            Expanded(child: _CategoryPageContent()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      drawer: const AdminDrawerWrapper(),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Kategori Yonetimi',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textWhite),
            tooltip: 'Yeni Kategori',
            onPressed: () => _showCategoryForm(context, category: null),
          ),
        ],
      ),
      body: const _CategoryList(),
    );
  }
}

// ─────────────────────────────────────────────
// Desktop içerik sarmalayıcı (başlık + liste)
// ─────────────────────────────────────────────
class _CategoryPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Row(
            children: [
              const Text(
                'Kategori Yonetimi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Kategori'),
                onPressed: () => _showCategoryForm(context, category: null),
              ),
            ],
          ),
        ),
        const Expanded(child: _CategoryList()),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Liste — API FutureProvider ile okuma
// Yazma (ekle/düzenle/sil/toggle) hâlâ Firestore üzerinden.
// ─────────────────────────────────────────────
class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(_apiCategoriesProvider);

    return asyncCategories.when(
      loading: () => _buildShimmer(),
      error: (e, _) => _buildError(e.toString()),
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmpty(context);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            // Firestore'daki CategoryModel ile uyumluluk için basit adapter
            final firestoreCat = _toFirestoreCategory(cat);
            return _CategoryListItem(
              category: firestoreCat,
              onEdit: () =>
                  _showCategoryForm(context, category: firestoreCat),
              onDelete: () => _confirmDelete(context, ref, firestoreCat),
            );
          },
        );
      },
    );
  }

  /// ApiCategoryModel'i mevcut CategoryModel'e dönüştürür.
  /// Yazma işlemleri Firestore'a gittiğinden CategoryModel.id = slug kullanılır.
  CategoryModel _toFirestoreCategory(ApiCategoryModel cat) {
    return CategoryModel(
      id: cat.id.toString(),
      name: cat.name,
      slug: cat.slug,
      iconName: cat.iconName,
      color: cat.color,
      sortOrder: cat.sortOrder,
      isActive: cat.isActive,
      parentId: cat.parentId?.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Kategoriler yüklenemedi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined,
              color: AppColors.textHint, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Henuz kategori yok',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ilk kategoriyi eklemek icin + butonuna basin.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Kategori Ekle'),
            onPressed: () => _showCategoryForm(context, category: null),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tekil Satir
// ─────────────────────────────────────────────
class _CategoryListItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListItem({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = _hexToColor(category.color);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Renk kutucugu
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: itemColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),

            // Ikon + Isim
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: itemColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.category_outlined,
                  size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    category.iconName.isEmpty
                        ? 'ikon yok'
                        : category.iconName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // sortOrder badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '#${category.sortOrder}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // isActive switch — sadece gorsel, tiklama olmali
            _ActiveToggle(category: category),
            const SizedBox(width: 4),

            // Düzenle
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onEdit,
              tooltip: 'Düzenle',
              padding: const EdgeInsets.all(6),
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            // Sil
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Sil',
              padding: const EdgeInsets.all(6),
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// isActive Toggle — AdminCategoryRepository üzerinden günceller
// ─────────────────────────────────────────────
class _ActiveToggle extends ConsumerStatefulWidget {
  final CategoryModel category;
  const _ActiveToggle({required this.category});

  @override
  ConsumerState<_ActiveToggle> createState() => _ActiveToggleState();
}

class _ActiveToggleState extends ConsumerState<_ActiveToggle> {
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminCategoryRepositoryProvider);
      await repo.toggleActive(widget.category);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const SizedBox(
            width: 36,
            height: 20,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          )
        : Switch(
            value: widget.category.isActive,
            activeThumbColor: AppColors.primary,
            onChanged: (_) => _toggle(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
  }
}

// ─────────────────────────────────────────────
// Silme Onay Dialogu — AdminCategoryRepository üzerinden siler
// ─────────────────────────────────────────────
Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, CategoryModel category) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Kategoriyi Sil',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        '"${category.name}" kategorisini silmek istediğinizden emin misiniz? Bu işlemi geri alamazsınız.',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: const Size(80, 40),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final repo = ref.read(adminCategoryRepositoryProvider);
    await repo.deleteCategory(category.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${category.name}" silindi.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme hatasi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
// BottomSheet Form (Ekle / Düzenle)
// ─────────────────────────────────────────────
void _showCategoryForm(BuildContext context,
    {required CategoryModel? category}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryFormSheet(category: category),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryModel? category;
  const _CategoryFormSheet({required this.category});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _sortCtrl;
  late bool _isActive;
  late String _selectedColorHex;
  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _iconCtrl = TextEditingController(text: cat?.iconName ?? '');
    _sortCtrl =
        TextEditingController(text: cat?.sortOrder.toString() ?? '0');
    _isActive = cat?.isActive ?? true;
    _selectedColorHex =
        cat?.color ?? _kPresetColorHex[0]; // varsayilan turkuaz
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final slug = name
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      final sortOrder = int.tryParse(_sortCtrl.text.trim()) ?? 0;
      final now = DateTime.now();

      final repo = ref.read(adminCategoryRepositoryProvider);

      if (_isEdit) {
        // Güncelle
        final updated = widget.category!.copyWith(
          name: name,
          slug: slug,
          iconName: _iconCtrl.text.trim(),
          color: _selectedColorHex,
          sortOrder: sortOrder,
          isActive: _isActive,
          updatedAt: now,
        );
        await repo.saveCategory(category: updated, isUpdate: true);
      } else {
        // Yeni ekle — id boş geçilir, repository auto-ID kullanır
        final newCategory = CategoryModel(
          id: '',
          name: name,
          slug: slug,
          iconName: _iconCtrl.text.trim(),
          color: _selectedColorHex,
          sortOrder: sortOrder,
          isActive: _isActive,
          parentId: null,
          createdAt: now,
          updatedAt: now,
        );
        await repo.saveCategory(category: newCategory, isUpdate: false);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? '"$name" kategorisi güncellendi.'
                  : '"$name" kategorisi eklendi.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayit hatasi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding:
          EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Baslik
              Text(
                _isEdit ? 'Kategoriyi Düzenle' : 'Yeni Kategori',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Ad alani
              _FormLabel('Kategori Adi *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'ornegin: Gazli Icecekler',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Kategori adi zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ikon alani
              _FormLabel('Ikon Adi'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _iconCtrl,
                decoration: const InputDecoration(
                  hintText: 'kategori_adi (ornegin: ic_cat_water)',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Sort order
              _FormLabel('Siralama No'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _sortCtrl,
                decoration: const InputDecoration(
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final n = int.tryParse(v);
                    if (n == null) return 'Gecerli bir sayi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Renk secici
              _FormLabel('Renk'),
              const SizedBox(height: 10),
              _ColorPicker(
                selectedHex: _selectedColorHex,
                onSelected: (hex) =>
                    setState(() => _selectedColorHex = hex),
              ),
              const SizedBox(height: 16),

              // isActive toggle
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktif',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Pasif kategoriler uygulamada gorünmez',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textWhite,
                          ),
                        )
                      : Text(_isEdit ? 'Kaydet' : 'Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Preset Renk Secici
// ─────────────────────────────────────────────
class _ColorPicker extends StatelessWidget {
  final String selectedHex;
  final ValueChanged<String> onSelected;

  const _ColorPicker({
    required this.selectedHex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(_kPresetColors.length, (i) {
        final hex = _kPresetColorHex[i];
        final color = _kPresetColors[i];
        final isSelected = selectedHex == hex;

        return GestureDetector(
          onTap: () => onSelected(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.textPrimary, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check,
                    color: AppColors.textWhite, size: 18)
                : null,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Yardimci Widgetlar
// ─────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
