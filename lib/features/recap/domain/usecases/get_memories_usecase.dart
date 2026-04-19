import 'package:momen/features/recap/domain/entities/memory_post.dart';
import 'package:momen/features/recap/domain/repositories/memories_repository.dart';

class GetMemoriesUseCase {
  const GetMemoriesUseCase(this._repository);

  final MemoriesRepository _repository;

  Future<List<MemoryPost>> call({String? ownerUserId, int page = 0}) {
    return _repository.getMemories(ownerUserId: ownerUserId, page: page);
  }
}