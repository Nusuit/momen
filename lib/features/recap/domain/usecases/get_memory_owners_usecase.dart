import 'package:momen/features/recap/domain/entities/memory_owner_option.dart';
import 'package:momen/features/recap/domain/repositories/memories_repository.dart';

class GetMemoryOwnersUseCase {
  const GetMemoryOwnersUseCase(this._repository);

  final MemoriesRepository _repository;

  Future<List<MemoryOwnerOption>> call() {
    return _repository.getMemoryOwners();
  }
}
