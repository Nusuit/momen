import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/feed/domain/entities/captured_post.dart';
import 'package:momen/features/feed/domain/repositories/captured_post_repository.dart';
import 'package:momen/features/feed/domain/usecases/create_captured_post_usecase.dart';
import 'package:momen/features/feed/presentation/state/create_post_controller.dart';

class _FakeCapturedPostRepository implements CapturedPostRepository {
  _FakeCapturedPostRepository(this._handler);

  final Future<void> Function(
    CapturedPost post,
    void Function(double progress, String message)? onProgress,
  ) _handler;

  @override
  Future<void> createPost(
    CapturedPost post, {
    void Function(double progress, String message)? onProgress,
  }) {
    return _handler(post, onProgress);
  }

  @override
  Future<void> revealPost(String postId) async {}
}

void main() {
  const samplePost = CapturedPost(
    imageLocalPath: '/tmp/photo.jpg',
    caption: 'Dinner 120k',
    amountVnd: 120000,
  );

  test('createPost emits progress then success', () async {
    final fakeRepository = _FakeCapturedPostRepository((post, onProgress) async {
      onProgress?.call(0.2, 'Uploading image...');
      onProgress?.call(0.8, 'Saving post...');
    });

    final container = ProviderContainer(
      overrides: [
        createCapturedPostUseCaseProvider.overrideWithValue(
          CreateCapturedPostUseCase(fakeRepository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final states = <CreatePostState>[];
    final sub = container.listen<CreatePostState>(
      createPostControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await container.read(createPostControllerProvider.notifier).createPost(samplePost);

    expect(states.first.isSubmitting, false);
    expect(
      states.any((state) => state.isSubmitting && state.message == 'Uploading image...'),
      isTrue,
    );
    expect(
      states.any((state) => state.isSubmitting && state.message == 'Saving post...'),
      isTrue,
    );

    final last = container.read(createPostControllerProvider);
    expect(last.isSuccess, isTrue);
    expect(last.progress, 1);
    expect(last.message, 'Completed');
  });

  test('createPost emits failure state when use case throws', () async {
    final fakeRepository = _FakeCapturedPostRepository((post, onProgress) async {
      throw Exception('network failure');
    });

    final container = ProviderContainer(
      overrides: [
        createCapturedPostUseCaseProvider.overrideWithValue(
          CreateCapturedPostUseCase(fakeRepository),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      () => container.read(createPostControllerProvider.notifier).createPost(samplePost),
      throwsException,
    );

    final state = container.read(createPostControllerProvider);
    expect(state.isSubmitting, isFalse);
    expect(state.isSuccess, isFalse);
    expect(state.error, isNotNull);
  });

  test('reset returns state to idle', () async {
    final fakeRepository = _FakeCapturedPostRepository((post, onProgress) async {});

    final container = ProviderContainer(
      overrides: [
        createCapturedPostUseCaseProvider.overrideWithValue(
          CreateCapturedPostUseCase(fakeRepository),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(createPostControllerProvider.notifier).createPost(samplePost);
    container.read(createPostControllerProvider.notifier).reset();

    final state = container.read(createPostControllerProvider);
    expect(state.isSubmitting, isFalse);
    expect(state.isSuccess, isFalse);
    expect(state.progress, 0);
    expect(state.message, '');
  });
}
