import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/models/order_summary_model.dart';

// ---------------------------------------------------------------------------
// Kullanici listesi notifier
// ---------------------------------------------------------------------------

class AdminUsersNotifier
    extends Notifier<AsyncValue<List<AdminUserModel>>> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  AsyncValue<List<AdminUserModel>> build() {
    final sub = _db
        .collection(AppConstants.usersCollection)
        .orderBy('name')
        .snapshots()
        .listen(
          (snap) {
            state = AsyncValue.data(
              snap.docs.map(AdminUserModel.fromFirestore).toList(),
            );
          },
          onError: (Object e, StackTrace st) =>
              state = AsyncValue.error(e, st),
        );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  Future<void> loadUsers() async {} // Stream otomatik güncelliyor

  Future<void> updateUserRole(String userId, UserRole role) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleBlock(String userId) async {
    final user = state.value?.where((u) => u.id == userId).firstOrNull;
    if (user == null) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'isActive': user.isBlocked, // isBlocked=true → isActive=false, toggle
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AsyncValue<List<AdminUserModel>>>(
  AdminUsersNotifier.new,
);

// ---------------------------------------------------------------------------
// Filtre state'leri (Riverpod 3.x: NotifierProvider yerine)
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
// Filtrelenmis kullanici listesi
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

// Sayfalanmis kullanici listesi (15/sayfa)
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
  return ((filtered.length) / kUsersPageSize).ceil().clamp(1, 9999);
});

// ---------------------------------------------------------------------------
// Kullanici istatistikleri (header)
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
      total: 0,
      customer: 0,
      fieldAgent: 0,
      delivery: 0,
      admin: 0,
      blocked: 0,
    ),
    error: (_, __) => const UserStats(
      total: 0,
      customer: 0,
      fieldAgent: 0,
      delivery: 0,
      admin: 0,
      blocked: 0,
    ),
  );
});

// ---------------------------------------------------------------------------
// Tek kullanici detayi
// ---------------------------------------------------------------------------

final userDetailProvider =
    FutureProvider.family<AdminUserModel, String>((ref, userId) async {
  // Yüklü listeden önce bak
  final cached = ref
      .watch(adminUsersProvider)
      .value
      ?.where((u) => u.id == userId)
      .firstOrNull;
  if (cached != null) return cached;

  // Firestore'dan direkt çek
  final doc = await FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .get();
  if (!doc.exists) throw Exception('Kullanici bulunamadi: $userId');
  return AdminUserModel.fromFirestore(doc);
});

// ---------------------------------------------------------------------------
// Kullaniciya ait siparisler
// ---------------------------------------------------------------------------

final userOrdersProvider =
    FutureProvider.family<List<OrderSummaryModel>, String>((ref, userId) async {
  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.ordersCollection)
      .where('customerId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .get();
  return snap.docs.map(OrderSummaryModel.fromFirestore).toList();
});
