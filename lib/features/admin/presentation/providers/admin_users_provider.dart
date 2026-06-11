import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/network/api_endpoints.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/models/order_summary_model.dart';

// ---------------------------------------------------------------------------
// Kullanici listesi notifier — REST API tabanlı
// ---------------------------------------------------------------------------

class AdminUsersNotifier
    extends Notifier<AsyncValue<List<AdminUserModel>>> {
  Dio get _dio => ref.read(apiClientProvider).dio;

  @override
  AsyncValue<List<AdminUserModel>> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final users = await _fetchUsers();
      state = AsyncValue.data(users);
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 403) {
        state = AsyncValue.error(
          const AdminRoleException(
            'Yetersiz yetki: admin rolünüz gerekiyor.\n'
            'Çözüm: Veritabanında rolünüzü "admin" yapın.',
          ),
          st,
        );
      } else {
        state = AsyncValue.error(e, st);
      }
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<List<AdminUserModel>> _fetchUsers() async {
    final response = await _dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {'per_page': 200, 'page': 1},
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List? ?? [];
    return data
        .map((j) => AdminUserModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleBlock(String userId) async {
    final user = state.value?.where((u) => u.id == userId).firstOrNull;
    if (user == null) return;
    final id = int.tryParse(userId);
    if (id == null) return;

    await _dio.put(
      ApiEndpoints.adminUserStatus(id),
      data: {'is_active': user.isBlocked}, // isBlocked=true → aktifleştir
    );

    state = AsyncValue.data(
      state.value!.map((u) {
        if (u.id != userId) return u;
        return u.copyWith(isBlocked: !u.isBlocked);
      }).toList(),
    );
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    final id = int.tryParse(userId);
    if (id == null) return;

    await _dio.put(
      '${ApiEndpoints.adminUsers}/$id/role',
      data: {'role': role.value},
    );

    state = AsyncValue.data(
      state.value!.map((u) {
        if (u.id != userId) return u;
        return u.copyWith(role: role);
      }).toList(),
    );
  }
}

class AdminRoleException implements Exception {
  final String message;
  const AdminRoleException(this.message);
  @override
  String toString() => message;
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AsyncValue<List<AdminUserModel>>>(
  AdminUsersNotifier.new,
);

// ---------------------------------------------------------------------------
// Filtre state'leri
// ---------------------------------------------------------------------------

class _UserSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final userSearchProvider =
    NotifierProvider<_UserSearchNotifier, String>(_UserSearchNotifier.new);

class _UserRoleFilterNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() => null;
  void set(UserRole? v) => state = v;
}

final userRoleFilterProvider =
    NotifierProvider<_UserRoleFilterNotifier, UserRole?>(
        _UserRoleFilterNotifier.new);

class _UserPageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

final userPageProvider =
    NotifierProvider<_UserPageNotifier, int>(_UserPageNotifier.new);

// ---------------------------------------------------------------------------
// Filtrelenmis kullanici listesi (client-side, cache üzerinde)
// ---------------------------------------------------------------------------

final filteredUsersProvider = Provider<List<AdminUserModel>>((ref) {
  final usersAsync = ref.watch(adminUsersProvider);
  final search = ref.watch(userSearchProvider).toLowerCase().trim();
  final roleFilter = ref.watch(userRoleFilterProvider);

  return usersAsync.when(
    data: (users) {
      var result = users;
      if (search.isNotEmpty) {
        result = result
            .where((u) =>
                u.name.toLowerCase().contains(search) ||
                u.phone.contains(search))
            .toList();
      }
      if (roleFilter != null) {
        result = result.where((u) => u.role == roleFilter).toList();
      }
      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

const int kUsersPageSize = 15;

final pagedUsersProvider = Provider<List<AdminUserModel>>((ref) {
  final filtered = ref.watch(filteredUsersProvider);
  final page = ref.watch(userPageProvider);
  final start = page * kUsersPageSize;
  if (start >= filtered.length) return [];
  final end = (start + kUsersPageSize).clamp(0, filtered.length);
  return filtered.sublist(start, end);
});

final totalUserPagesProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredUsersProvider);
  return (filtered.length / kUsersPageSize).ceil().clamp(1, 9999);
});

// ---------------------------------------------------------------------------
// Kullanici istatistikleri
// ---------------------------------------------------------------------------

class UserStats {
  final int total;
  final int customer;
  final int fieldAgent;
  final int delivery;
  final int admin;
  final int blocked;

  const UserStats({
    required this.total,
    required this.customer,
    required this.fieldAgent,
    required this.delivery,
    required this.admin,
    required this.blocked,
  });
}

final userStatsProvider = Provider<UserStats>((ref) {
  final usersAsync = ref.watch(adminUsersProvider);
  return usersAsync.when(
    data: (users) => UserStats(
      total: users.length,
      customer: users.where((u) => u.role == UserRole.customer).length,
      fieldAgent: users.where((u) => u.role == UserRole.fieldAgent).length,
      delivery: users.where((u) => u.role == UserRole.delivery).length,
      admin: users.where((u) => u.role == UserRole.admin).length,
      blocked: users.where((u) => u.isBlocked).length,
    ),
    loading: () => const UserStats(
        total: 0, customer: 0, fieldAgent: 0, delivery: 0, admin: 0, blocked: 0),
    error: (_, __) => const UserStats(
        total: 0, customer: 0, fieldAgent: 0, delivery: 0, admin: 0, blocked: 0),
  );
});

// ---------------------------------------------------------------------------
// Tek kullanici detayi
// ---------------------------------------------------------------------------

final userDetailProvider =
    FutureProvider.family<AdminUserModel, String>((ref, userId) async {
  final cached = ref
      .watch(adminUsersProvider)
      .value
      ?.where((u) => u.id == userId)
      .firstOrNull;
  if (cached != null) return cached;

  final dio = ref.read(apiClientProvider).dio;
  final id = int.tryParse(userId);
  if (id == null) throw Exception('Gecersiz kullanici ID: $userId');

  final response = await dio.get('${ApiEndpoints.adminUsers}/$id');
  final body = response.data as Map<String, dynamic>;
  final data = body['data'] as Map<String, dynamic>? ?? body;
  return AdminUserModel.fromJson(data);
});

// ---------------------------------------------------------------------------
// Kullaniciya ait siparisler (admin orders API üzerinden filtre)
// ---------------------------------------------------------------------------

final userOrdersProvider =
    FutureProvider.family<List<OrderSummaryModel>, String>(
        (ref, userId) async {
  final dio = ref.read(apiClientProvider).dio;
  final response = await dio.get(
    ApiEndpoints.adminOrders,
    queryParameters: {'user_id': userId, 'per_page': 20, 'page': 1},
  );
  final body = response.data as Map<String, dynamic>;
  final data = body['data'] as List? ?? [];
  return data.map((j) {
    final m = j as Map<String, dynamic>;
    return OrderSummaryModel(
      id: (m['id'] ?? '').toString(),
      orderNo: m['order_number'] as String? ?? m['orderNo'] as String? ?? '',
      date: m['created_at'] != null
          ? DateTime.parse(m['created_at'] as String)
          : DateTime.now(),
      amount: (m['total'] as num? ?? 0).toDouble(),
      status: OrderStatus.fromString(m['status'] as String? ?? 'pending'),
      itemCount: (m['items_count'] as num? ?? m['itemCount'] as num? ?? 0).toInt(),
    );
  }).toList();
});
