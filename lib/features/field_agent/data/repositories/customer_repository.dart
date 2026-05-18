import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';

// ---------------------------------------------------------------------------
// CustomerPage -- paginated sorgu sonucu
// ---------------------------------------------------------------------------

class CustomerPage {
  final List<UserModel> customers;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  const CustomerPage({
    required this.customers,
    required this.hasMore,
    this.lastDoc,
  });
}

// ---------------------------------------------------------------------------
// CustomerRepository
// ---------------------------------------------------------------------------

class CustomerRepository {
  final FirebaseFirestore _firestore;
  final OrderRepository _orderRepository;

  // U+F8FF: Unicode Private Use Area son karakteri.
  // Firestore prefix search trick: field >= prefix && field <= prefix + suffix
  // String.fromCharCode garantili encode -- literal karakterden daha guvenli.
  static final String _kUnicodeSuffix = String.fromCharCode(0xF8FF);

  CustomerRepository({
    FirebaseFirestore? firestore,
    required OrderRepository orderRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _orderRepository = orderRepository;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _firestore.collection(AppConstants.customersCollection);

  // =========================================================================
  // Listeleme ve Arama
  // =========================================================================

  /// Paginated musteri listesi -- role:'customer', name'e gore sirali.
  /// [lastDoc]: bir onceki sayfanin son dokumani (cursor-based pagination).
  Future<CustomerPage> getCustomers({DocumentSnapshot? lastDoc}) async {
    var query = _customers
        .where('role', isEqualTo: UserRole.customer.value)
        .orderBy('name')
        .limit(AppConstants.pageSize);

    if (lastDoc != null) query = query.startAfterDocument(lastDoc);

    final snap = await query.get();
    final customers =
        snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
    final hasMore = snap.docs.length == AppConstants.pageSize;
    final nextCursor = hasMore ? snap.docs.last : null;

    return CustomerPage(
      customers: customers,
      hasMore: hasMore,
      lastDoc: nextCursor,
    );
  }

  /// Tek musteri -- uid ile getir.
  /// role != customer ise null dondurur (guvenligi repository katmaninda korur).
  Future<UserModel?> getCustomerById(String uid) async {
    final doc = await _customers.doc(uid).get();
    if (!doc.exists) return null;
    final user = UserModel.fromFirestore(doc);
    if (user.role != UserRole.customer) return null;
    return user;
  }

  /// Telefon prefix arama -- Firestore range query.
  /// phone >= query AND phone <= query + U+F8FF seklinde prefix match yapar.
  Future<List<UserModel>> searchByPhone(String phone) async {
    if (phone.isEmpty) return [];

    final snap = await _customers
        .where('role', isEqualTo: UserRole.customer.value)
        .where('phone', isGreaterThanOrEqualTo: phone)
        .where('phone', isLessThanOrEqualTo: phone + _kUnicodeSuffix)
        .limit(AppConstants.pageSize)
        .get();

    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  /// Isim arama -- Firestore full-text desteklemedigi icin client-side filtrele.
  /// Ilk 50 kayit getirilir, sonra Dart'ta contains kontrolu yapilir.
  Future<List<UserModel>> searchByName(String name) async {
    if (name.isEmpty) return [];

    final snap = await _customers
        .where('role', isEqualTo: UserRole.customer.value)
        .orderBy('name')
        .limit(50)
        .get();

    final all = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
    final q = name.toLowerCase();
    return all.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  // =========================================================================
  // Musteri Yazma
  // =========================================================================

  /// Yeni musteri olustur -- auto-ID, role zorunlu olarak 'customer'.
  /// Saha personeli terminal modunda kullanir.
  Future<UserModel> createCustomer({
    required String name,
    required String phone,
  }) async {
    final now = DateTime.now();
    final docRef = _customers.doc(); // Firestore auto-ID

    final user = UserModel(
      uid: docRef.id,
      name: name,
      phone: phone,
      role: UserRole.customer,
      createdAt: now,
    );

    await docRef.set(user.toFirestore());
    return user;
  }

  /// Mevcut musteri bilgilerini guncelle.
  /// role alani guncellenmez -- guvenligi repository katmaninda zorla.
  Future<void> updateCustomer(UserModel customer) async {
    await _customers.doc(customer.uid).update({
      'name': customer.name,
      'phone': customer.phone,
      // role degistirilemez -- guvenligi repository katmaninda korur.
      // Admin rol degisikligi icin auth_repository kullanilmali.
    });
  }

  // =========================================================================
  // Siparis gecmisi
  // =========================================================================

  /// Musterinin siparis gecmisini getir -- OrderRepository'e delege et.
  Future<List<OrderModel>> getCustomerOrders(String customerId) {
    return _orderRepository.getUserOrders(customerId);
  }

  // =========================================================================
  // Adres yonetimi -- users/{uid}/addresses subcollection
  // =========================================================================

  /// Musterinin adreslerini getir.
  /// isDefault:true adresler liste basinda gelir (descending order).
  /// Mevcut top-level addresses koleksiyonu korunmakta -- bu subcollection
  /// field_agent terminal modunda yeni adres eklemek icin kullanilir.
  Future<List<Map<String, dynamic>>> getCustomerAddresses(
    String customerId,
  ) async {
    final snap = await _customers
        .doc(customerId)
        .collection(AppConstants.customerAddressesSubcollection)
        .orderBy('isDefault', descending: true)
        .get();

    return snap.docs
        .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
        .toList();
  }

  /// Musteriye yeni adres ekle -- subcollection.
  /// userId ve createdAt sunucu tarafindan eklenir.
  Future<void> addCustomerAddress(
    String customerId,
    Map<String, dynamic> address,
  ) async {
    await _customers
        .doc(customerId)
        .collection(AppConstants.customerAddressesSubcollection)
        .add({
      ...address,
      'userId': customerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Singleton CustomerRepository -- OrderRepository'e bagimli.
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    orderRepository: ref.watch(orderRepositoryProvider),
  );
});

/// Ilk sayfa musteriler -- FutureProvider.
/// Sonraki sayfa icin [CustomerRepository.getCustomers(lastDoc: ...)] kullan.
final customersProvider = FutureProvider<CustomerPage>((ref) {
  return ref.watch(customerRepositoryProvider).getCustomers();
});

/// Tek musteri -- uid ile.
final customerByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) {
  if (uid.isEmpty) return Future.value(null);
  return ref.watch(customerRepositoryProvider).getCustomerById(uid);
});

/// Musteri siparis gecmisi -- uid ile.
final customerOrdersProvider =
    FutureProvider.family<List<OrderModel>, String>((ref, uid) {
  if (uid.isEmpty) return Future.value([]);
  return ref.watch(customerRepositoryProvider).getCustomerOrders(uid);
});
