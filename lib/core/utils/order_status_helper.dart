import 'package:flutter/material.dart';

import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/orders/domain/entities/order_entity.dart';

/// Sipariş durumlarına göre paylaşılan renk/ikon eşlemesi.
///
/// `order_list_screen.dart` ve `order_detail_screen.dart` arasında tutarlılığı
/// sağlamak için tek bir yerden yönetilir. Renkler CLAUDE.md / Fuska Design
/// System'deki durum paletiyle birebir eşleşir:
/// Pending=#FF9800, Confirmed=#00A6AB, Preparing=#E73A99 (primary),
/// OnTheWay=#13275A (secondary), Delivered=#43A047, Cancelled=#F44336.
Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AppColors.statusPending;
    case OrderStatus.confirmed:
      return AppColors.statusConfirmed;
    case OrderStatus.preparing:
      return AppColors.statusPreparing;
    case OrderStatus.onTheWay:
      return AppColors.statusOnTheWay;
    case OrderStatus.delivered:
      return AppColors.statusDelivered;
    case OrderStatus.cancelled:
      return AppColors.statusCancelled;
  }
}

/// Sipariş durumuna göre anlamlı/ayırt edici Material ikon.
IconData orderStatusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.access_time_outlined;
    case OrderStatus.confirmed:
      return Icons.check_circle_outline;
    case OrderStatus.preparing:
      return Icons.inventory_2_outlined;
    case OrderStatus.onTheWay:
      return Icons.local_shipping_outlined;
    case OrderStatus.delivered:
      return Icons.done_all_rounded;
    case OrderStatus.cancelled:
      return Icons.cancel_outlined;
  }
}
