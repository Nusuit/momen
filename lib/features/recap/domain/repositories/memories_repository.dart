import 'package:momen/features/recap/domain/entities/memory_post.dart';
import 'package:momen/features/recap/domain/entities/memory_owner_option.dart';
import 'package:momen/features/recap/domain/entities/reveal_reminder.dart';

abstract class MemoriesRepository {
  Future<List<MemoryPost>> getMemories({String? ownerUserId, int page = 0});

  Future<List<MemoryOwnerOption>> getMemoryOwners();

  Future<void> updateCaption({
    required String postId,
    required String caption,
  });

  Future<void> deletePost(String postId);

  Future<void> reportPost({
    required String postId,
    required String reason,
  });

  Future<void> setReaction({
    required String postId,
    required String reactionType,
  });

  Future<List<RevealReminder>> getPendingRevealReminders();

  Future<void> resolveRevealReminder({
    required String reminderId,
    required bool reveal,
  });
}
