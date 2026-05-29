import 'package:dartz/dartz.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/delivery_route_entity.dart';
import '../../domain/repositories/i_delivery_repository.dart';
import '../datasources/delivery_remote_datasource.dart';

class DeliveryRepositoryImpl implements IDeliveryRepository {
  final IDeliveryRemoteDatasource _remoteDatasource;
  final CacheManager _cacheManager;

  DeliveryRepositoryImpl({
    required IDeliveryRemoteDatasource remoteDatasource,
    required CacheManager cacheManager,
  })  : _remoteDatasource = remoteDatasource,
        _cacheManager = cacheManager;

  @override
  Future<Either<Failure, List<DeliveryRouteEntity>>> getDeliveryRoute() async {
    final cached = _cacheManager
        .getCachedData<List<dynamic>>(CacheKeys.deliveryOrders);
    if (cached != null) {
      try {
        // Cache'den geri yükle — delivery orders kısa TTL'li
      } catch (_) {
        await _cacheManager.invalidate(CacheKeys.deliveryOrders);
      }
    }

    try {
      final models = await _remoteDatasource.getDeliveryOrders();
      final entities = models.map((m) => m.toEntity()).toList();

      await _cacheManager.cacheData(
        CacheKeys.deliveryOrders,
        models
            .map((m) => {
                  'id': m.id,
                  'order_number': m.orderNumber,
                  'status': m.status,
                  'total': m.total,
                })
            .toList(),
        ttl: CacheKeys.deliveryOrdersTtl,
      );

      return Right(entities);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, DeliveryRouteEntity>> confirmDelivery(
      String orderId) async {
    final id = int.tryParse(orderId);
    if (id == null) {
      return const Left(NotFoundFailure('Gecersiz siparis ID'));
    }
    try {
      final model = await _remoteDatasource.deliverOrder(id);
      await _cacheManager.invalidate(CacheKeys.deliveryOrders);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, DeliveryRouteEntity>> updateDeliveryStatus(
    String orderId,
    String status,
  ) async {
    final id = int.tryParse(orderId);
    if (id == null) {
      return const Left(NotFoundFailure('Gecersiz siparis ID'));
    }
    try {
      final model = switch (status) {
        'on_the_way' => await _remoteDatasource.markOnTheWay(id),
        'delivered' => await _remoteDatasource.deliverOrder(id),
        _ => await _remoteDatasource.assignOrder(id),
      };
      await _cacheManager.invalidate(CacheKeys.deliveryOrders);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }
}
