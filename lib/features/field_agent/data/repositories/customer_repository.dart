import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/network/api_endpoints.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';
import 'package:nisa_ticaret/features/auth/data/models/api_user_model.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';

// ---------------------------------------------------------------------------
// CustomerRepository — API tabanlı (HF Space REST)
//
// Önceki Firestore implementasyonu kaldırıldı.
// Müşteri okuma/yazma işlemleri ApiEndpoints.adminUsers üzerinden yapılır.
// ---------------------------------------------------------------------------

class CustomerRepository {
  final Dio _dio;

  CustomerRepository({required Dio dio}) : _dio = dio;

  // =========================================================================
  // Listeleme ve Arama
  // =========================================================================

  /// Telefon numarasına göre müşteri arama — admin/users?search=phone
  Future<List<UserModel>> searchByPhone(String phone) async {
    if (phone.isEmpty) return [];
    try {
      final response = await _dio.get(
        ApiEndpoints.adminUsers,
        queryParameters: {'search': phone, 'role': 'customer', 'per_page': 20},
      );
      return _parseUserList(response.data);
    } on DioException {
      return [];
    }
  }

  /// İsme göre müşteri arama — admin/users?search=name
  Future<List<UserModel>> searchByName(String name) async {
    if (name.isEmpty) return [];
    try {
      final response = await _dio.get(
        ApiEndpoints.adminUsers,
        queryParameters: {'search': name, 'role': 'customer', 'per_page': 50},
      );
      return _parseUserList(response.data);
    } on DioException {
      return [];
    }
  }

  // =========================================================================
  // Müşteri Yazma
  // =========================================================================

  /// Yeni müşteri oluştur — API üzerinden.
  /// Bu işlem desteklenmiyor: API'de müşteri oluşturma endpoint'i yok.
  /// Field agent terminal modunda müşteri kaydı için backend endpoint gereklidir.
  Future<UserModel> createCustomer({
    required String name,
    required String phone,
  }) async {
    throw UnsupportedError(
      'Müşteri oluşturma API endpoint\'i mevcut değil. '
      'Backend eklendiğinde bu metod güncellenmeli.',
    );
  }

  /// Mevcut müşteri bilgilerini güncelle — API üzerinden.
  /// Bu işlem desteklenmiyor: API'de müşteri güncelleme endpoint'i yok.
  Future<void> updateCustomer(UserModel customer) async {
    throw UnsupportedError(
      'Müşteri güncelleme API endpoint\'i mevcut değil.',
    );
  }

  // =========================================================================
  // Siparis gecmisi
  // =========================================================================

  /// Müşterinin sipariş geçmişi — API'den orders?customer_id=x ile çekilebilir.
  /// Şu an OrderRepository (Firestore tabanlı) refactor edilmediğinden boş döndürülür.
  /// İleride API sipariş endpoint'i buraya entegre edilmeli.
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    return [];
  }

  // =========================================================================
  // Adres yönetimi — API'deki addresses endpoint'i üzerinden
  // =========================================================================

  /// Müşterinin adreslerini getir — /v1/addresses (kendi token'ı üzerinden).
  /// Field agent başka müşteri adreslerini göremez — bu endpoint desteklenmiyor.
  Future<List<Map<String, dynamic>>> getCustomerAddresses(
    String customerId,
  ) async {
    return [];
  }

  /// Müşteriye yeni adres ekle — şu an desteklenmiyor.
  Future<void> addCustomerAddress(
    String customerId,
    Map<String, dynamic> address,
  ) async {
    throw UnsupportedError(
      'Başka müşteri adına adres ekleme endpoint\'i mevcut değil.',
    );
  }

  // =========================================================================
  // Private Helpers
  // =========================================================================

  List<UserModel> _parseUserList(dynamic body) {
    List<dynamic> rawList = [];
    if (body is List) {
      rawList = body;
    } else if (body is Map) {
      final data = body['data'];
      if (data is List) rawList = data;
    }
    return rawList.map((j) {
      final apiUser = ApiUserModel.fromJson(j as Map<String, dynamic>);
      return UserModel.fromApiUser(apiUser);
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Singleton CustomerRepository — Dio tabanlı.
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return CustomerRepository(dio: dio);
});

/// Müşteri sipariş geçmişi — şu an boş döndürülür.
/// autoDispose: müşteri detay ekranı kapanınca bellek serbest bırakılır.
final customerOrdersFromRepoProvider =
    FutureProvider.autoDispose.family<List<OrderModel>, String>((ref, uid) {
  if (uid.isEmpty) return Future.value([]);
  return ref.watch(customerRepositoryProvider).getCustomerOrders(uid);
});
