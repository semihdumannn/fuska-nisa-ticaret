import 'package:equatable/equatable.dart';

/// Bildirim tipi — backend (Laravel) ile ortaktır.
/// Backend değerleri: 'order_update', 'promotion', 'system'
enum NotificationType {
  orderUpdate,
  promotion,
  system;

  String get value {
    switch (this) {
      case NotificationType.orderUpdate:
        return 'order_update';
      case NotificationType.promotion:
        return 'promotion';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'promotion':
        return NotificationType.promotion;
      default:
        return NotificationType.system;
    }
  }
}

/// Backend API: GET /v1/notifications
///
/// Laravel `NotificationResource` JSON şeması:
/// {
///   "id": 1,
///   "type": "order_update",
///   "type_label": "Order Update",
///   "title": "...",
///   "body": "...",
///   "data": {...},
///   "is_read": false,
///   "read_at": null,
///   "created_at": "2026-06-10T12:00:00+00:00"
/// }
class NotificationModel extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Bildirim data payload'ı.
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

  /// Backend API JSON'dan model oluştur.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'system'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Bildirim data payload'ından go_router route path'i döner.
  /// Örnek: "/orders/abc123"
  String? get route => data['route'] as String?;

  /// Sipariş bildirimlerindeki orderId.
  String? get orderId => data['orderId']?.toString() ?? data['order_id']?.toString();

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
