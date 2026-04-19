import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/feed/data/datasources/feed_post_remote_datasource.dart';
import 'package:momen/features/feed/data/repositories_impl/captured_post_repository_impl.dart';
import 'package:momen/features/feed/domain/entities/captured_post.dart';
import 'package:momen/features/feed/domain/usecases/create_captured_post_usecase.dart';

final _feedPostRemoteDataSourceProvider =
    Provider<FeedPostRemoteDataSource>((ref) {
  return FeedPostRemoteDataSource(ref.watch(supabaseClientProvider));
});

final _capturedPostRepositoryProvider =
    Provider<CapturedPostRepositoryImpl>((ref) {
  return CapturedPostRepositoryImpl(ref.watch(_feedPostRemoteDataSourceProvider));
});

final createCapturedPostUseCaseProvider =
    Provider<CreateCapturedPostUseCase>((ref) {
  return CreateCapturedPostUseCase(ref.watch(_capturedPostRepositoryProvider));
});

final createPostControllerProvider =
    NotifierProvider<CreatePostController, CreatePostState>(
  CreatePostController.new,
);

class CreatePostController extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState.idle();

  Future<void> createPost(CapturedPost post) async {
    state = const CreatePostState.submitting(
      progress: 0.05,
      message: 'Preparing upload...',
    );

    try {
      await ref.read(createCapturedPostUseCaseProvider).call(
            post,
            onProgress: (progress, message) {
              state = CreatePostState.submitting(
                progress: progress,
                message: message,
              );
            },
          );
      state = const CreatePostState.success();
    } catch (error) {
      state = CreatePostState.failure(error);
      rethrow;
    }
  }

  void reset() {
    state = const CreatePostState.idle();
  }
}

class CreatePostState {
  const CreatePostState._({
    required this.isSubmitting,
    required this.progress,
    required this.message,
    this.error,
    required this.isSuccess,
  });

  const CreatePostState.idle()
      : this._(
          isSubmitting: false,
          progress: 0,
          message: '',
          isSuccess: false,
        );

  const CreatePostState.submitting({
    required double progress,
    required String message,
  }) : this._(
          isSubmitting: true,
          progress: progress,
          message: message,
          isSuccess: false,
        );

  const CreatePostState.success()
      : this._(
          isSubmitting: false,
          progress: 1,
          message: 'Completed',
          isSuccess: true,
        );

  const CreatePostState.failure(Object error)
      : this._(
          isSubmitting: false,
          progress: 0,
          message: '',
          error: error,
          isSuccess: false,
        );

  final bool isSubmitting;
  final double progress;
  final String message;
  final Object? error;
  final bool isSuccess;
}