import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momen/features/auth/domain/repositories/auth_repository.dart';
import 'package:momen/features/auth/domain/usecases/auth_usecases.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  test('RequiresProfileCompletionUseCase returns repository value', () async {
    when(() => repository.requiresProfileCompletion())
        .thenAnswer((_) async => true);

    final useCase = RequiresProfileCompletionUseCase(repository);
    final result = await useCase.call();

    expect(result, isTrue);
    verify(() => repository.requiresProfileCompletion()).called(1);
  });

  test('CompleteProfileUseCase forwards payload to repository', () async {
    final dateOfBirth = DateTime(1998, 5, 21);

    when(
      () => repository.completeProfile(
        fullName: any(named: 'fullName'),
        dateOfBirth: any(named: 'dateOfBirth'),
      ),
    ).thenAnswer((_) async {});

    final useCase = CompleteProfileUseCase(repository);

    await useCase.call(
      fullName: 'Alice Nguyen',
      dateOfBirth: dateOfBirth,
    );

    verify(
      () => repository.completeProfile(
        fullName: 'Alice Nguyen',
        dateOfBirth: dateOfBirth,
      ),
    ).called(1);
  });
}
