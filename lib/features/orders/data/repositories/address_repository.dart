import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/cache/cache_keys.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/address_model.dart';
import 'package:nisa_ticaret/features/profile/data/providers/profile_data_providers.dart';
import 'package:nisa_ticaret/features/profile/domain/entities/address_entity.dart';
import 'package:nisa_ticaret/features/profile/domain/usecases/get_addresses_usecase.dart';

class AddressRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  AddressRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.addressesCollection);

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
AddressModel _entityToModel(AddressEntity entity) {
  return AddressModel(
    id: entity.id?.toString() ?? '',
    userId: '',
    label: entity.title,
    fullAddress: entity.fullAddress,
    district: entity.district ?? '',
    city: entity.city,
    lat: entity.latitude,
    lng: entity.longitude,
    isDefault: entity.isDefault,
  );
}

final addressesProvider = FutureProvider<List<AddressModel>>((ref) async {
  // Kullanıcı giriş yapmamışsa boş döndür — 401 hatasını önler
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  // Kullanıcıya özel cache key — farklı kullanıcılar birbirinin adresini göremez
  final userAddressKey = '${CacheKeys.addresses}_${user.uid}';

  final cache = ref.read(cacheManagerProvider);
  final rawCached = cache.getCachedData<List>(userAddressKey);
  if (rawCached != null) {
    return rawCached
        .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  final repo = ref.watch(apiProfileRepositoryProvider);
  final result = await GetAddressesUsecase(repo)();
  return result.fold(
    (failure) => <AddressModel>[],
    (entities) {
      final models = entities.map(_entityToModel).toList();
      cache.cacheData(
        userAddressKey,
        models.map((m) => m.toJson()).toList(),
        ttl: CacheKeys.addressesTtl,
      ).ignore();
      return models;
    },
  );
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
