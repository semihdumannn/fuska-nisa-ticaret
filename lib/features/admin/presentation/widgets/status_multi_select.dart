import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_order_model.dart';
import '../providers/admin_orders_provider.dart';

/// Durum coklu secim dropdown widget'i.
/// Overlay ile acilir, CheckboxListTile listesi gosterir.
class StatusMultiSelectDropdown extends ConsumerStatefulWidget {
  const StatusMultiSelectDropdown({super.key});

  @override
  ConsumerState<StatusMultiSelectDropdown> createState() =>
      _StatusMultiSelectDropdownState();
}

class _StatusMultiSelectDropdownState
    extends ConsumerState<StatusMultiSelectDropdown> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 44),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
                child: Container(
                  width: 240,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: _StatusCheckboxList(onClose: _closeDropdown),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(orderStatusFilterProvider);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected.isNotEmpty
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected.isNotEmpty
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
              width: selected.isNotEmpty ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                selected.isEmpty
                    ? 'Durum'
                    : '${selected.length} durum',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected.isNotEmpty
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              if (selected.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${selected.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCheckboxList extends ConsumerWidget {
  final VoidCallback onClose;

  const _StatusCheckboxList({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(orderStatusFilterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text(
                'Durum Filtrele',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (selected.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    ref.read(orderStatusFilterProvider.notifier).set({});
                  },
                  child: const Text(
                    'Temizle',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            children: AdminOrderStatus.values.map((status) {
              final isChecked = selected.contains(status);
              return InkWell(
                onTap: () {
                  final current = Set<AdminOrderStatus>.from(selected);
                  if (isChecked) {
                    current.remove(status);
                  } else {
                    current.add(status);
                  }
                  ref.read(orderStatusFilterProvider.notifier).set(current);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (v) {
                          final current =
                              Set<AdminOrderStatus>.from(selected);
                          if (v == true) {
                            current.add(status);
                          } else {
                            current.remove(status);
                          }
                          ref
                              .read(orderStatusFilterProvider.notifier)
                              .set(current);
                        },
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onClose,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Uygula',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
