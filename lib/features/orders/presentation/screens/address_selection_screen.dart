import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/orders/data/models/address_model.dart';
import 'package:nisa_ticaret/core/cache/cache_keys.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/address_repository.dart';
import 'package:nisa_ticaret/features/profile/data/providers/profile_data_providers.dart';

class AddressSelectionScreen extends ConsumerWidget {
  /// true → seç ve geri don, false → yonet
  final bool isSelectionMode;

  const AddressSelectionScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Adreslerim'),
        actions: [
          if (!isSelectionMode)
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.addressForm),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ekle'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      floatingActionButton: isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addressForm),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(
                'Yeni Adres Ekle',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: addressesAsync.when(
        loading: () => const _ShimmerList(),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(addressesProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return _EmptyState(isSelectionMode: isSelectionMode);
          }
          return _AddressList(
            addresses: addresses,
            isSelectionMode: isSelectionMode,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Adres listesi + son item olarak "Yeni Adres Ekle"
// ---------------------------------------------------------------------------
class _AddressList extends ConsumerWidget {
  final List<AddressModel> addresses;
  final bool isSelectionMode;

  const _AddressList({
    required this.addresses,
    required this.isSelectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = isSelectionMode ? addresses.length : addresses.length + 1;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (!isSelectionMode && index == addresses.length) {
          return _AddNewAddressTile();
        }
        final address = addresses[index];
        return _AddressCard(
          address: address,
          isSelectionMode: isSelectionMode,
          onTap: () async {
            if (isSelectionMode) {
              if (!address.isDefault) {
                final addressId = int.tryParse(address.id);
                if (addressId != null) {
                  try {
                    await ref.read(apiProfileRepositoryProvider).setDefaultAddress(addressId);
                    await ref.read(cacheManagerProvider).invalidateByPrefix(CacheKeys.addresses);
                    ref.invalidate(addressesProvider);
                  } catch (_) {}
                }
              }
              if (context.mounted) context.pop(address);
            } else {
              context.push(AppRoutes.addressForm, extra: address);
            }
          },
          onSetDefault: () async {
            final repo = ref.read(addressRepositoryProvider);
            if (repo == null) return;
            try {
              await repo.setDefault(address.id);
              // Cache'i temizle → defaultAddressProvider anında güncellenir
              await ref.read(cacheManagerProvider).invalidateByPrefix(CacheKeys.addresses);
              ref.invalidate(addressesProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Varsayilan adres ayarlanamadi'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          onEdit: () => context.push(AppRoutes.addressForm, extra: address),
          onDelete: () => _confirmDelete(context, ref, address),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Adresi Sil'),
        content: Text(
          '"${address.label}" adresini silmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(addressRepositoryProvider);
      if (repo == null) return;
      try {
        await repo.deleteAddress(address.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adres silinemedi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Tek adres karti
// ---------------------------------------------------------------------------
class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isSelectionMode,
    required this.onTap,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelectionMode && address.isDefault
                ? AppColors.primary
                : AppColors.border,
            width: isSelectionMode && address.isDefault ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LabelChip(label: address.label),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        _DefaultChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address.fullAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${address.district}, ${address.city}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (address.notes != null && address.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      address.notes!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelectionMode)
              Icon(
                address.isDefault
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: address.isDefault
                    ? AppColors.primary
                    : AppColors.textHint,
                size: 24,
              )
            else
              PopupMenuButton<_AddressAction>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _AddressAction.setDefault:
                      onSetDefault();
                    case _AddressAction.edit:
                      onEdit();
                    case _AddressAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: _AddressAction.setDefault,
                      child: Row(
                        children: [
                          Icon(Icons.star_outline,
                              size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Varsayilan Yap'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: _AddressAction.edit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: _AddressAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Sil',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

enum _AddressAction { setDefault, edit, delete }

// ---------------------------------------------------------------------------
// Label chip (Ev / Is / Diger)
// ---------------------------------------------------------------------------
class _LabelChip extends StatelessWidget {
  final String label;

  const _LabelChip({required this.label});

  Color get _color {
    switch (label) {
      case 'Ev':
        return AppColors.accent;
      case 'Is':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Varsayilan" chip
// ---------------------------------------------------------------------------
class _DefaultChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Varsayilan',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Yeni Adres Ekle" tile (liste sonu)
// ---------------------------------------------------------------------------
class _AddNewAddressTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.addressForm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Yeni Adres Ekle',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bos durum
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final bool isSelectionMode;

  const _EmptyState({required this.isSelectionMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 72,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henuz adresiniz yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Siparisleriniz icin bir teslimat adresi ekleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.addressForm),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Adres Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hata durumu
// ---------------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Adresler yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer yuklenme durumu (3 placeholder kart)
// ---------------------------------------------------------------------------
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surface,
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
