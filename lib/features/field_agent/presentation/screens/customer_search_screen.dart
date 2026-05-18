import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // FutureProvider, StateProvider, ConsumerWidget
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/field_agent/data/repositories/customer_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final customerSearchProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.watch(customerRepositoryProvider).searchByName(query);
});

class _RecentCustomerIdsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void update(List<String> ids) => state = ids;
}

final recentCustomerIdsProvider =
    NotifierProvider<_RecentCustomerIdsNotifier, List<String>>(
  _RecentCustomerIdsNotifier.new,
);

final _recentCustomersProvider =
    FutureProvider.family<List<UserModel>, List<String>>((ref, ids) async {
  if (ids.isEmpty) return [];
  // whereIn ile tek sorguda çek (N+1 yerine 1 Firestore okuma)
  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .where(FieldPath.documentId, whereIn: ids)
      .get();
  return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CustomerSearchScreen extends ConsumerStatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  ConsumerState<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRecentIds();
  }

  Future<void> _loadRecentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_customers') ?? [];
    ref.read(recentCustomerIdsProvider.notifier).update(list);
  }

  Future<void> _addToRecent(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_customers') ?? [];
    list.remove(uid);
    list.insert(0, uid);
    if (list.length > 5) list.removeLast();
    await prefs.setStringList('recent_customers', list);
    ref.read(recentCustomerIdsProvider.notifier).update(List.from(list));
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _navigateToDetail(UserModel user) {
    _addToRecent(user.uid);
    context.push(
      AppRoutes.customerDetail.replaceFirst(':uid', user.uid),
      extra: user,
    );
  }

  Future<void> _showAddCustomerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Yeni Musteri Ekle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ad giriniz' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '05XX XXX XX XX',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Telefon giriniz' : null,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogContext).pop();
              await _saveNewCustomer(
                nameController.text.trim(),
                phoneController.text.trim(),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewCustomer(String name, String phone) async {
    try {
      await ref.read(customerRepositoryProvider).createCustomer(
            name: name,
            phone: phone,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müşteri başarıyla eklendi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Musteri Ara'),
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: AppColors.textWhite),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          Expanded(
            child: _query.isEmpty
                ? _RecentCustomers(onTap: _navigateToDetail)
                : _SearchResults(
                    query: _query,
                    onTap: _navigateToDetail,
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Ad veya telefon numarasi...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textHint),
                onPressed: onClear,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecentCustomers extends ConsumerWidget {
  final ValueChanged<UserModel> onTap;

  const _RecentCustomers({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentIds = ref.watch(recentCustomerIdsProvider);
    if (recentIds.isEmpty) {
      return const _EmptyState(message: 'Henuz musteri goruntulenmedi');
    }

    final customersAsync = ref.watch(_recentCustomersProvider(recentIds));
    return customersAsync.when(
      loading: () => _buildShimmerList(),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (customers) {
        if (customers.isEmpty) {
          return const _EmptyState(message: 'Henuz musteri goruntulenmedi');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Son Musteriler',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: customers.length,
                itemBuilder: (_, i) => _CustomerCard(
                  user: customers[i],
                  onTap: onTap,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  final ValueChanged<UserModel> onTap;

  const _SearchResults({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(customerSearchProvider(query));
    return resultsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (_, __) => const _ShimmerCard(),
      ),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (users) {
        if (users.isEmpty) {
          return const _EmptyState(message: 'Sonuc bulunamadi');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: users.length,
          itemBuilder: (_, i) => _CustomerCard(user: users[i], onTap: onTap),
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final UserModel user;
  final ValueChanged<UserModel> onTap;

  const _CustomerCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.name);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onTap(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _AvatarCircle(initials: initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _OrderButton(onPressed: () => onTap(user)),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initials;

  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OrderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _OrderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(80, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Sipariş Al'),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_search, size: 64, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Bir hata olustu',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
