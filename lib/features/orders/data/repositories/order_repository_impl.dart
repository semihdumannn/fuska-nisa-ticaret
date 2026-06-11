import 'package:dartz/dartz.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../delivery/data/datasources/delivery_remote_datasource.dart';
import '../../../delivery/data/models/delivery_order_model.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/api_order_model.dart';

class OrderRepositoryImpl implements IOrderRepository {
  final IOrderRemoteDatasource _remoteDatasource;
  final IDeliveryRemoteDatasource _deliveryDatasource;

  OrderRepositoryImpl(
    this._remoteDatasource,
    this._deliveryDatasource,
  );

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders({
    int page = 1,
    int perPage = 20,
    OrderStatus? status,
  }) async {
    try {
      final models = await _remoteDatasource.getOrders(
        page: page,
        perPage: perPage,
        status: status?.apiValue,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderDetail(int id) async {
    try {
      final model = await _remoteDatasource.getOrderDetail(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> createOrder({
    required List<Map<String, dynamic>> items,
    required int addressId,
    String? paymentMethod,
    String? notes,
    String? couponCode,
  }) async {
    try {
      final model = await _remoteDatasource.createOrder(
        items: items,
        addressId: addressId,
        paymentMethod: paymentMethod,
        notes: notes,
        couponCode: couponCode,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> cancelOrder(int orderId) async {
    try {
      final model = await _remoteDatasource.cancelOrder(orderId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> updateOrderStatus({
    required int orderId,
    required OrderStatus newStatus,
    String? note,
  }) async {
    try {
      final model = await _remoteDatasource.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus.apiValue,
        note: note,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getDeliveryRoute() async {
    try {
      final models = await _deliveryDatasource.getDeliveryOrders();
      return Right(models.map(_deliveryModelToOrderEntity).toList());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> confirmDelivery({
    required int orderId,
    String? notes,
  }) async {
    try {
      final model = await _deliveryDatasource.deliverOrder(orderId);
      return Right(_deliveryModelToOrderEntity(model));
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  OrderEntity _deliveryModelToOrderEntity(DeliveryOrderModel model) {
    return ApiOrderModel.fromJson({
      'id': model.id,
      'order_number': model.orderNumber,
      'status': model.status,
      'total': model.total,
      'subtotal': model.total,
      'items': [],
      'address': {
        'full_address': model.address.fullAddress,
        'latitude': model.address.latitude,
        'longitude': model.address.longitude,
      },
      'created_at': DateTime.now().toIso8601String(),
    }).toEntity();
  }
}
