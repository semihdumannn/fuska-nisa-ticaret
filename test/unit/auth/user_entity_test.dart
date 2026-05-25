import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/auth/domain/entities/user_entity.dart';

void main() {
  test('admin role', () {
    const u = UserEntity(id: 1, name: 'A', phone: '+90', role: 'admin');
    expect(u.isAdmin, true);
    expect(u.isCustomer, false);
  });

  test('customer role', () {
    const u = UserEntity(id: 2, name: 'B', phone: '+90', role: 'customer');
    expect(u.isCustomer, true);
    expect(u.isAdmin, false);
  });
}
