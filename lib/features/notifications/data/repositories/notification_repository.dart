import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

/// Bildirim repository sözleşmesi.
/// Test ortamında mock implementasyon geçilebilir.
abstract class NotificationRepository {
  /// Kullanıcının bildirimlerini gerçek zamanlı dinle.
  /// Firestore şeması: `notifications/{userId}/items/{notificationId}`
  Stream<List<NotificationModel>> watchNotifications(String userId);

  /// Tek bildirimi okundu olarak işaretle.
  Future<void> markAsRead(String userId, String notificationId);

  /// Kullanıcının tüm okunmamış bildirimlerini okundu yap (batch write).
  Future<void> markAllAsRead(String userId);
}

/// Firestore implementasyonu.
class FirestoreNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// `notifications/{userId}/items` subcollection referansı.
  CollectionReference<Map<String, dynamic>> _itemsRef(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Okuma — gerçek zamanlı stream (cache yok, CLAUDE.md kuralı)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    return _itemsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(100) // Son 100 bildirim — Spark plan Firestore okuma tasarrufu
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Yazma
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _itemsRef(userId).doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('NotificationRepository.markAsRead: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadDocs = await _itemsRef(userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadDocs.docs.isEmpty) return;

      // Batch ile toplu güncelleme — tek Firestore işlemi
      final batch = _firestore.batch();
      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      debugPrint(
        'NotificationRepository.markAllAsRead: ${unreadDocs.docs.length} bildirim okundu işaretlendi',
      );
    } catch (e) {
      debugPrint('NotificationRepository.markAllAsRead: $e');
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository();
});
