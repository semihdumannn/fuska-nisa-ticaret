import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';

abstract class IOrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getOrders({
    int page = 1,
    int perPage = 20,
    OrderStatus? status,
  });

  Future<Either<Failure, OrderEntity>> getOrderDetail(int id);

  Future<Either<Failure, OrderEntity>> createOrder({
    required List<Map<String, dynamic>> items,
    required int addressId,
    String? notes,
    String? couponCode,
  });

  Future<Either<Failure, OrderEntity>> cancelOrder(int orderId);

  Future<Either<Failure, OrderEntity>> updateOrderStatus({
    required int orderId,
    required OrderStatus newStatus,
    String? note,
  });

  // Teslimat ekibi icin
  Future<Either<Failure, List<OrderEntity>>> getDeliveryRoute();

  Future<Either<Failure, OrderEntity>> confirmDelivery({
    required int orderId,
    String? notes,
  });
}
