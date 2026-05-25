import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nisa_ticaret/core/error/failures.dart';
import 'package:nisa_ticaret/features/auth/domain/entities/user_entity.dart';
import 'package:nisa_ticaret/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:nisa_ticaret/features/auth/domain/usecases/login_usecase.dart';

@GenerateMocks([IAuthRepository])
import 'login_usecase_test.mocks.dart';

void main() {
  late LoginUsecase sut;
  late MockIAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockIAuthRepository();
    sut = LoginUsecase(mockRepo);
  });

  const user = UserEntity(id: 1, name: 'Test', phone: '+90', role: 'customer');

  test('returns user on success', () async {
    when(mockRepo.loginWithPhoneOTP(
            phone: anyNamed('phone'), otp: anyNamed('otp')))
        .thenAnswer((_) async => const Right(user));

    final result = await sut(phone: '+90', otp: '123456');

    expect(result, const Right(user));
  });

  test('returns failure on error', () async {
    when(mockRepo.loginWithPhoneOTP(
            phone: anyNamed('phone'), otp: anyNamed('otp')))
        .thenAnswer((_) async => const Left(ServerFailure('Hata')));

    final result = await sut(phone: '+90', otp: 'bad');

    expect(result.isLeft(), true);
  });
}
