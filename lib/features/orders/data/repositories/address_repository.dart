import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/address_model.dart';

class AddressRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  AddressRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.addressesCollection);

  /// Kullanicinin adreslerini gercek zamanli dinle.
  /// orderBy Firestore'da composite index gerektirir; sıralama Dart'ta yapılır.
  Stream<List<AddressModel>> watchAddresses() {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => AddressModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return 0;
      });
      return list;
    });
  }

  /// Adres listesini tek seferlik cek
  Future<List<AddressModel>> getAddresses() async {
    final snap = await _collection
        .where('userId', isEqualTo: userId)
        .get();
    final list = snap.docs
        .map((doc) => AddressModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
    return list;
  }

  /// Yeni adres ekle (auto-ID)
  Future<void> addAddress(AddressModel address) async {
    final safe = address.copyWith(userId: userId);
    await _collection.add(safe.toFirestore());
  }

  /// Adres guncelle
  Future<void> updateAddress(AddressModel address) async {
    await _collection.doc(address.id).update(address.toFirestore());
  }

  /// Adres sil
  Future<void> deleteAddress(String addressId) async {
    await _collection.doc(addressId).delete();
  }

  /// Varsayilan adres ayarla (batch: once tumunu false, sonra secileni true)
  Future<void> setDefault(String addressId) async {
    final batch = _firestore.batch();

    final snap = await _collection
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    batch.update(
      _collection.doc(addressId),
      {'isDefault': true},
    );

    await batch.commit();
  }
}

// ---------------------------------------------------------------------------
// Repository provider — auth state'e bagli
// ---------------------------------------------------------------------------
final addressRepositoryProvider = Provider<AddressRepository?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (user) {
    if (user == null) return null;
    return AddressRepository(userId: user.uid);
  });
});

// ---------------------------------------------------------------------------
// Adres listesi stream
// ---------------------------------------------------------------------------
final addressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  // Auth henuz yukleniyor — loading state'de bekle (stream emit etmeden)
  if (authState.isLoading) return const Stream.empty();
  // Auth tamam ama kullanici yok — bos liste emit et (empty state goster)
  final repo = ref.watch(addressRepositoryProvider);
  if (repo == null) return Stream.value([]);
  return repo.watchAddresses();
});

// ---------------------------------------------------------------------------
// Varsayilan adres
// ---------------------------------------------------------------------------
final defaultAddressProvider = Provider<AddressModel?>((ref) {
  final addresses = ref.watch(addressesProvider).value ?? [];
  try {
    return addresses.firstWhere((a) => a.isDefault);
  } catch (_) {
    return addresses.isNotEmpty ? addresses.first : null;
  }
});
