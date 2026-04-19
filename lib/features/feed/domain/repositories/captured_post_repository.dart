import 'package:momen/features/feed/domain/entities/captured_post.dart';

abstract class CapturedPostRepository {
  Future<void> createPost(
    CapturedPost post, {
    void Function(double progress, String message)? onProgress,
  });

  Future<void> revealPost(String postId);
}