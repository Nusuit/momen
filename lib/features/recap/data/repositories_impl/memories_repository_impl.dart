import 'package:momen/features/recap/data/datasources/memories_remote_datasource.dart';
import 'package:momen/features/recap/domain/entities/memory_owner_option.dart';
import 'package:momen/features/recap/domain/entities/memory_post.dart';
import 'package:momen/features/recap/domain/entities/reveal_reminder.dart';
import 'package:momen/features/recap/domain/repositories/memories_repository.dart';

class MemoriesRepositoryImpl implements MemoriesRepository {
  const MemoriesRepositoryImpl(this._remoteDataSource);

  final MemoriesRemoteDataSource _remoteDataSource;

  @override
  Future<List<MemoryPost>> getMemories({String? ownerUserId, int page = 0}) {
    return _remoteDataSource.getMemories(ownerUserId: ownerUserId, page: page);
  }

  @override
  Future<List<MemoryOwnerOption>> getMemoryOwners() {
    return _remoteDataSource.getMemoryOwners();
  }

  @override
  Future<void> updateCaption({
    required String postId,
    required String caption,
  }) {
    return _remoteDataSource.updateCaption(postId: postId, caption: caption);
  }

  @override
  Future<void> deletePost(String postId) {
    return _remoteDataSource.deletePost(postId);
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) {
    return _remoteDataSource.reportPost(postId: postId, reason: reason);
  }

  @override
  Future<void> setReaction({
    required String postId,
    required String reactionType,
  }) {
    return _remoteDataSource.setReaction(
      postId: postId,
      reactionType: reactionType,
    );
  }

  @override
  Future<List<RevealReminder>> getPendingRevealReminders() {
    return _remoteDataSource.getPendingRevealReminders();
  }

  @override
  Future<void> resolveRevealReminder({
    required String reminderId,
    required bool reveal,
  }) {
    return _remoteDataSource.resolveRevealReminder(
      reminderId: reminderId,
      reveal: reveal,
    );
  }
}
