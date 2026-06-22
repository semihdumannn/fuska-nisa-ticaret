import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';

/// Admin personel listesi repository.
///
/// Admin panelinde sipariş atama ekranlarında kullanılan
/// saha personeli (field_agent) ve teslimat personeli (delivery)
/// listelerini Firestore [users] koleksiyonundan çeker.
///
/// Bu listelerin doğrudan provider veya presentation katmanında
/// Firestore.instance çağrısı yapması yerine bu repository üzerinden
/// erişilmesi repository pattern'ini korur ve test edilebilirliği artırır.
class AdminStaffRepository {
  final FirebaseFirestore _firestore;

  AdminStaffRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(AppConstants.usersCollection);

  // ─── Field Agents ────────────────────────────────────────────────────────────

  /// Aktif saha personelini isim sırasıyla getirir.
  ///
  /// Sonuç tip-safe anonymous record listesidir: `({String id, String name})`.
  Future<List<({String id, String name})>> getFieldAgents() async {
    final snap = await _usersCol
        .where('role', isEqualTo: 'field_agent')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return (id: doc.id, name: data['name'] as String? ?? '');
    }).toList();
  }

  // ─── Delivery Persons ────────────────────────────────────────────────────────

  /// Aktif teslimat personelini isim sırasıyla getirir.
  Future<List<({String id, String name})>> getDeliveryPersons() async {
    final snap = await _usersCol
        .where('role', isEqualTo: 'delivery')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return (id: doc.id, name: data['name'] as String? ?? '');
    }).toList();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final adminStaffRepositoryProvider = Provider<AdminStaffRepository>((ref) {
  return AdminStaffRepository();
});
