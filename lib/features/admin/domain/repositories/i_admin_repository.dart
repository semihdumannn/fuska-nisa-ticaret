import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_order_entity.dart';
import '../entities/admin_user_entity.dart';
import '../entities/dashboard_entity.dart';

abstract class IAdminRepository {
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats();

  Future<Either<Failure, List<DailySalesEntity>>> getDailySales({
    required DateTime from,
    required DateTime to,
  });

  Future<Either<Failure, List<TopProductEntity>>> getTopProducts({int limit = 10});

  Future<Either<Failure, List<AdminUserEntity>>> getUsers({
    int page = 1,
    String? role,
    String? searchQuery,
  });

  Future<Either<Failure, AdminUserEntity>> getUserDetail(String userId);

  Future<Either<Failure, void>> toggleUserStatus(String userId, bool isActive);

  Future<Either<Failure, List<AdminOrderEntity>>> getOrders({
    int page = 1,
    String? status,
    DateTime? from,
    DateTime? to,
  });

  Future<Either<Failure, AdminOrderEntity>> assignDelivery({
    required int orderId,
    required String deliveryPersonId,
  });
}
