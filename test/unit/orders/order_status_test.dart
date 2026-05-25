import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/orders/domain/entities/order_entity.dart';

void main() {
  group('OrderStatus', () {
    test('fromString pending',
        () => expect(OrderStatus.fromString('pending'), OrderStatus.pending));
    test('fromString on_the_way',
        () => expect(OrderStatus.fromString('on_the_way'), OrderStatus.onTheWay));
    test('fromString delivered',
        () => expect(OrderStatus.fromString('delivered'), OrderStatus.delivered));
    test('apiValue on_the_way',
        () => expect(OrderStatus.onTheWay.apiValue, 'on_the_way'));
    test('delivered isFinal',
        () => expect(OrderStatus.delivered.isFinal, true));
    test('pending isActive',
        () => expect(OrderStatus.pending.isActive, true));
    test('pending displayName',
        () => expect(OrderStatus.pending.displayName, isNotEmpty));
  });
}
