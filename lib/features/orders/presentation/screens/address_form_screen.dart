import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/data/turkish_cities.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/address_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/address_repository.dart'
    show addressesProvider;
import 'package:nisa_ticaret/features/orders/presentation/screens/map_picker_screen.dart';
import 'package:nisa_ticaret/features/profile/domain/entities/address_entity.dart';
import 'package:nisa_ticaret/features/profile/presentation/providers/api_profile_provider.dart'
    show apiAddressesNotifierProvider;

const _kLabels = ['Ev', 'Is', 'Diger'];

class AddressFormScreen extends ConsumerStatefulWidget {
  /// null → yeni ekle, deger → duzenle
  final AddressModel? address;

  const AddressFormScreen({super.key, this.address});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedLabel;
  late TextEditingController _fullAddressController;
  late TextEditingController _notesController;
  late bool _isDefault;

  String _selectedCity = '';
  String _selectedDistrict = '';
  double? _lat;
  double? _lng;
  bool _isLoading = false;
  bool _hasChanges = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _selectedLabel = addr?.label ?? _kLabels.first;
    _fullAddressController = TextEditingController(text: addr?.fullAddress ?? '');
    _notesController = TextEditingController(text: addr?.notes ?? '');
    _isDefault = addr?.isDefault ?? false;
    _selectedCity = addr?.city ?? AppConstants.defaultCity;
    _selectedDistrict = addr?.district ?? '';
    _lat = addr?.lat;
    _lng = addr?.lng;

    _fullAddressController.addListener(_onChanged);
    _notesController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _fullAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Degisiklikler Kaybolacak'),
        content: const Text(
          'Degisiklikleri kaybetmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Hayir'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Evet, Cik'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _showError('Oturum bulunamadı. Lutfen tekrar giris yapin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(apiAddressesNotifierProvider.notifier);
      final existingId = _isEditing
          ? int.tryParse(widget.address!.id)
          : null;

      final entity = AddressEntity(
        id: existingId,
        title: _selectedLabel,
        fullName: user.name.isNotEmpty ? user.name : user.phone,
        phone: user.phone,
        addressLine: _fullAddressController.text.trim(),
        city: _selectedCity,
        district: _selectedDistrict.isEmpty ? null : _selectedDistrict,
        latitude: _lat,
        longitude: _lng,
        isDefault: _isDefault,
      );

      bool success;
      if (_isEditing && existingId != null) {
        success = await notifier.updateAddress(entity);
      } else {
        success = await notifier.addAddress(entity);
      }

      if (mounted) {
        if (success) {
          // Adresler listesini yenile
          ref.invalidate(addressesProvider);
          setState(() => _hasChanges = false);
          context.pop();
        } else {
          _showError('Adres kaydedilemedi. Tekrar deneyin.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Adres kaydedilemedi: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCityPicker() async {
    final selected = await _showSearchPicker(
      context: context,
      title: 'İl Seç',
      items: TurkishCities.cities,
      selected: _selectedCity,
    );
    if (selected != null && selected != _selectedCity) {
      setState(() {
        _selectedCity = selected;
        _selectedDistrict = '';
        _hasChanges = true;
      });
    }
  }

  Future<void> _showDistrictPicker() async {
    final selected = await _showSearchPicker(
      context: context,
      title: 'İlçe Seç',
      items: TurkishCities.districtsOf(_selectedCity),
      selected: _selectedDistrict,
    );
    if (selected != null) {
      setState(() {
        _selectedDistrict = selected;
        _hasChanges = true;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(_isEditing ? 'Adresi Düzenle' : 'Yeni Adres'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && context.mounted) context.pop();
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Etiket secici
              const _SectionTitle(title: 'Adres Etiketi'),
              const SizedBox(height: 8),
              _LabelSelector(
                selected: _selectedLabel,
                onChanged: (label) {
                  setState(() {
                    _selectedLabel = label;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Tam Adres
              const _SectionTitle(title: 'Tam Adres'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullAddressController,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Sokak, bina no, daire',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tam adres giriniz';
                  }
                  if (value.trim().length < 10) {
                    return 'En az 10 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sehir (il) seçici
              const _SectionTitle(title: 'İl'),
              const SizedBox(height: 8),
              _PickerField(
                value: _selectedCity.isEmpty ? null : _selectedCity,
                hint: 'İl seçin',
                icon: Icons.location_city_outlined,
                onTap: () => _showCityPicker(),
                validator: (_) => _selectedCity.isEmpty ? 'İl seçiniz' : null,
              ),
              const SizedBox(height: 16),

              // İlçe seçici
              const _SectionTitle(title: 'İlçe'),
              const SizedBox(height: 8),
              _PickerField(
                value: _selectedDistrict.isEmpty ? null : _selectedDistrict,
                hint: _selectedCity.isEmpty ? 'Önce il seçin' : 'İlçe seçin',
                icon: Icons.map_outlined,
                enabled: _selectedCity.isNotEmpty,
                onTap: _selectedCity.isEmpty ? null : () => _showDistrictPicker(),
                validator: (_) => _selectedDistrict.isEmpty ? 'İlçe seçiniz' : null,
              ),
              const SizedBox(height: 16),

              // Tarif (opsiyonel)
              const _SectionTitle(title: 'Adres Tarifi (Opsiyonel)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Kirmizi bina, 2. kat...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Varsayilan adres switch
              // Material eklenmiştir — ListTile ink efektleri DecoratedBox
              // içinde kaybolmasın diye.
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value;
                        _hasChanges = true;
                      });
                    },
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    title: const Text(
                      'Varsayilan adres olarak ayarla',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Siparislerinizde otomatik secilir',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    secondary: const Icon(
                      Icons.star_outline,
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Haritadan konum seç
              OutlinedButton.icon(
                onPressed: () async {
                  final result =
                      await Navigator.of(context).push<MapPickerResult>(
                    MaterialPageRoute(
                      builder: (_) => MapPickerScreen(
                        initialLocation: (_lat != null && _lng != null)
                            ? LatLng(_lat!, _lng!)
                            : null,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _lat = result.location.latitude;
                      _lng = result.location.longitude;
                      // Geocoding sonuçlarını doldur (boşsa dokunma)
                      if (result.fullAddress != null &&
                          result.fullAddress!.isNotEmpty) {
                        _fullAddressController.text = result.fullAddress!;
                      }
                      if (result.city != null && result.city!.isNotEmpty) {
                        // Tam eşleşme ara, yoksa olduğu gibi ata
                        final match = TurkishCities.cities.firstWhere(
                          (c) => c.toLowerCase() ==
                              result.city!.toLowerCase(),
                          orElse: () => result.city!,
                        );
                        _selectedCity = match;
                        _selectedDistrict = ''; // şehir değişti, ilçeyi sıfırla
                      }
                      if (result.district != null &&
                          result.district!.isNotEmpty &&
                          _selectedCity.isNotEmpty) {
                        final districts = TurkishCities.districtsOf(_selectedCity);
                        final match = districts.firstWhere(
                          (d) => d.toLowerCase() ==
                              result.district!.toLowerCase(),
                          orElse: () => result.district!,
                        );
                        _selectedDistrict = match;
                      }
                      _hasChanges = true;
                    });
                  }
                },
                icon: Icon(
                  _lat != null ? Icons.location_on : Icons.map_outlined,
                  color: _lat != null ? AppColors.primary : null,
                ),
                label: Text(
                    _lat != null ? 'Konum Seçildi ✓' : 'Haritadan Konum Seç'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _lat != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  side: BorderSide(
                      color: _lat != null
                          ? AppColors.primary
                          : AppColors.border),
                ),
              ),
              const SizedBox(height: 24),

              // Kaydet butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textWhite,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Güncelle' : 'Kaydet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Etiket secici widget (Ev / Is / Diger)
// ---------------------------------------------------------------------------
class _LabelSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _LabelSelector({required this.selected, required this.onChanged});

  Color _chipColor(String label) {
    switch (label) {
      case 'Ev':
        return AppColors.accent;
      case 'Is':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _chipIcon(String label) {
    switch (label) {
      case 'Ev':
        return Icons.home_outlined;
      case 'Is':
        return Icons.business_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _kLabels.map((label) {
        final isSelected = selected == label;
        final color = _chipColor(label);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(label),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _chipIcon(label),
                    color: isSelected ? color : AppColors.textHint,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Bolum basligi
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picker alanı — dropdown görünümlü, tap ile bottom sheet açar
// ---------------------------------------------------------------------------
class _PickerField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const _PickerField({
    required this.hint,
    required this.icon,
    this.value,
    this.enabled = true,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: enabled ? onTap : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: enabled ? AppColors.surface : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasError
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 20,
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textHint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value ?? hint,
                        style: TextStyle(
                          fontSize: 14,
                          color: value != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textHint),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Arama destekli liste seçici — bottom sheet
// ---------------------------------------------------------------------------
Future<String?> _showSearchPicker({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchPickerSheet(
      title: title,
      items: items,
      selected: selected,
    ),
  );
}

class _SearchPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String selected;

  const _SearchPickerSheet({
    required this.title,
    required this.items,
    required this.selected,
  });

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  late List<String> _filtered;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchController.addListener(_filter);
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
              .where((item) => item.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Tutucu çubuk
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Başlık
          Text(widget.title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Liste
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final item = _filtered[i];
                final isSelected = item == widget.selected;
                return ListTile(
                  title: Text(item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                          color: AppColors.primary, size: 18)
                      : null,
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
