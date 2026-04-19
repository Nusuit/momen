import 'package:momen/features/feed/domain/entities/captured_post.dart';
import 'package:momen/features/feed/domain/repositories/captured_post_repository.dart';

class CreateCapturedPostUseCase {
  const CreateCapturedPostUseCase(this._repository);

  final CapturedPostRepository _repository;

  Future<void> call(
    CapturedPost post, {
    void Function(double progress, String message)? onProgress,
  }) {
    return _repository.createPost(post, onProgress: onProgress);
  }
}

class RevealPostUseCase {
  const RevealPostUseCase(this._repository);

  final CapturedPostRepository _repository;

  Future<void> call(String postId) => _repository.revealPost(postId);
}
