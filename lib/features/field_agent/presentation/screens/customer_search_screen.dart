import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nisa_ticaret/core/network/api_endpoints.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/admin/data/models/admin_user_model.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// AdminUserModel → UserModel dönüşümü (UID olarak API id kullanılır)
extension AdminUserToUser on AdminUserModel {
  UserModel toUserModel() => UserModel(
        uid: id,
        name: name,
        phone: phone,
        email: email,
        role: role,
        isActive: !isBlocked,
        createdAt: createdAt,
      );
}

// ---------------------------------------------------------------------------
// Providers — API tabanlı, Firestore yok
// ---------------------------------------------------------------------------

/// Arama: isim veya telefon numarasına göre API üzerinden müşteri ara
final customerSearchProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final dio = ref.watch(apiClientProvider).dio;
  final response = await dio.get(
    ApiEndpoints.adminUsers,
    queryParameters: {
      'search': query,
      'role': 'customer',
      'per_page': 20,
      'page': 1,
    },
  );

  final body = response.data as Map<String, dynamic>;
  final data = body['data'] as List? ?? [];
  return data
      .map((j) => AdminUserModel.fromJson(j as Map<String, dynamic>).toUserModel())
      .toList();
});

// ---------------------------------------------------------------------------
// Son müşteriler — SharedPreferences'ta JSON olarak saklanır
// ---------------------------------------------------------------------------

class _RecentCustomersNotifier extends Notifier<List<UserModel>> {
  static const _key = 'recent_customers_json';

  @override
  List<UserModel> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    final customers = jsonList
        .map((s) {
          try {
            final m = jsonDecode(s) as Map<String, dynamic>;
            return UserModel(
              uid: m['uid'] as String,
              name: m['name'] as String,
              phone: m['phone'] as String? ?? '',
              role: UserRole.fromString(m['role'] as String? ?? 'customer'),
              isActive: m['isActive'] as bool? ?? true,
              createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                  DateTime.now(),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<UserModel>()
        .toList();
    state = customers;
  }

  Future<void> addRecent(UserModel user) async {
    final updated = [user, ...state.where((u) => u.uid != user.uid)];
    if (updated.length > 8) updated.removeLast();
    state = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      updated.map((u) => jsonEncode({
            'uid': u.uid,
            'name': u.name,
            'phone': u.phone,
            'role': u.role.value,
            'isActive': u.isActive,
            'createdAt': u.createdAt.toIso8601String(),
          })).toList(),
    );
  }
}

final recentCustomersProvider =
    NotifierProvider<_RecentCustomersNotifier, List<UserModel>>(
  _RecentCustomersNotifier.new,
);

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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _selectCustomer(UserModel user) {
    ref.read(recentCustomersProvider.notifier).addRecent(user);
    context.push(
      AppRoutes.customerDetail.replaceFirst(':uid', user.uid),
      extra: user,
    );
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
        elevation: 0,
        title: const Text(
          'Müşteri Ara',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
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
                ? _RecentList(onTap: _selectCustomer)
                : _SearchResults(query: _query, onTap: _selectCustomer),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Bar
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
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Ad, soyad veya telefon numarası...',
          hintStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 14),
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
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent customers list
// ---------------------------------------------------------------------------

class _RecentList extends ConsumerWidget {
  final ValueChanged<UserModel> onTap;
  const _RecentList({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentCustomersProvider);

    if (recents.isEmpty) {
      return const _EmptyState(
        icon: Icons.person_search_rounded,
        message: 'Arama yaparak müşteri bulun',
        subtitle: 'Son görüntülenenler burada çıkar',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Son Müşteriler',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recents.length,
            itemBuilder: (_, i) =>
                _CustomerCard(user: recents[i], onTap: onTap),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search results
// ---------------------------------------------------------------------------

class _SearchResults extends ConsumerWidget {
  final String query;
  final ValueChanged<UserModel> onTap;
  const _SearchResults({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerSearchProvider(query));
    return async.when(
      loading: () => _ShimmerList(),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (users) {
        if (users.isEmpty) {
          return const _EmptyState(
            icon: Icons.search_off_rounded,
            message: 'Sonuç bulunamadı',
            subtitle: 'Farklı bir isim veya telefon numarası deneyin',
          );
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

// ---------------------------------------------------------------------------
// Customer card
// ---------------------------------------------------------------------------

class _CustomerCard extends StatelessWidget {
  final UserModel user;
  final ValueChanged<UserModel> onTap;
  const _CustomerCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = user.name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : user.name.isNotEmpty
            ? user.name[0].toUpperCase()
            : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: AppColors.surface,
      child: InkWell(
        onTap: () => onTap(user),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
              ),
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
                      user.phone.isNotEmpty ? user.phone : 'Telefon yok',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                  onPressed: () => onTap(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer, Empty, Error
// ---------------------------------------------------------------------------

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Bağlantı Hatası',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
