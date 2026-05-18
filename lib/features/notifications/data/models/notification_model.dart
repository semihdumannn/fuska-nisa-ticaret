import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Bildirim tipi — Cloud Functions ve Flutter tarafında ortaktır.
/// Cloud Functions'da string değerleri: 'order_status', 'new_order', 'promo', 'system'
enum NotificationType {
  orderStatus,
  newOrder,
  promo,
  system;

  String get value {
    switch (this) {
      case NotificationType.orderStatus:
        return 'order_status';
      case NotificationType.newOrder:
        return 'new_order';
      case NotificationType.promo:
        return 'promo';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'order_status':
        return NotificationType.orderStatus;
      case 'new_order':
        return NotificationType.newOrder;
      case 'promo':
        return NotificationType.promo;
      default:
        return NotificationType.system;
    }
  }
}

/// Firestore şeması: `notifications/{userId}/items/{notificationId}`
///
/// Cloud Functions admin SDK ile bu subcollection'a yazar.
/// Flutter istemcisi okur ve okundu olarak işaretler.
/// Yazma: Cloud Functions (admin SDK) veya Firestore rule'da admin rolü.
class NotificationModel extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// FCM data payload'ından gelen ek veriler.
  /// Zorunlu key: "route" (go_router path, örn. "/orders/abc123")
  /// İsteğe bağlı: "orderId"
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  // ─── Factory constructors ─────────────────────────────────────────────────

  /// Firestore dokümanından model oluştur.
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: NotificationType.fromString(map['type'] as String? ?? 'system'),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
    );
  }

  /// JSON'dan model — CacheService (Hive) için.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'system'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }

  // ─── Serialization ────────────────────────────────────────────────────────

  /// Firestore'a yazılacak map.
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }

  /// CacheService için JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'data': data,
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// FCM data payload'ından go_router route path'i döner.
  /// Örnek: "/orders/abc123"
  String? get route => data['route'] as String?;

  /// Sipariş bildirimlerindeki orderId.
  String? get orderId => data['orderId'] as String?;

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [id, type, isRead, createdAt];
}
