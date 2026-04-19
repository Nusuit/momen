import 'package:momen/features/feed/data/datasources/feed_post_remote_datasource.dart';
import 'package:momen/features/feed/domain/entities/captured_post.dart';
import 'package:momen/features/feed/domain/repositories/captured_post_repository.dart';

class CapturedPostRepositoryImpl implements CapturedPostRepository {
  const CapturedPostRepositoryImpl(this._remoteDataSource);

  final FeedPostRemoteDataSource _remoteDataSource;

  @override
  Future<void> createPost(
    CapturedPost post, {
    void Function(double progress, String message)? onProgress,
  }) {
    return _remoteDataSource.createPost(post, onProgress: onProgress);
  }

  @override
  Future<void> revealPost(String postId) =>
      _remoteDataSource.revealPost(postId);
}