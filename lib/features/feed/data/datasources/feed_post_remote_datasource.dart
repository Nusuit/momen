import 'dart:io';
import 'dart:developer' as developer;

import 'package:momen/features/feed/domain/entities/captured_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedPostRemoteDataSource {
  const FeedPostRemoteDataSource(this._client);

  final SupabaseClient? _client;

  Future<void> createPost(
    CapturedPost post, {
    void Function(double progress, String message)? onProgress,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in before posting.');
    }

    _log('Starting createPost', details: {
      'userIdPrefix': user.id.substring(0, 8),
      'captionLength': post.caption.length,
      'hasAmount': post.amountVnd != null,
    });

    final file = File(post.imageLocalPath);
    if (!file.existsSync()) {
      throw Exception('Captured image file is missing.');
    }

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      String? filePath;
      try {
        onProgress?.call(0.15, 'Uploading image...');
        filePath = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
        _log('Uploading image', details: {
          'attempt': attempt,
          'path': filePath,
        });
        await client.storage.from('post_images').upload(
              filePath,
              file,
              fileOptions: const FileOptions(
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );

        _log('Upload success', details: {
          'attempt': attempt,
          'path': filePath,
        });

        final publicUrl = client.storage
            .from('post_images')
            .getPublicUrl(filePath);

        onProgress?.call(0.8, 'Saving post...');
        _log('Inserting post row', details: {
          'attempt': attempt,
          'path': filePath,
        });
        await client.from('posts').insert({
          'user_id': user.id,
          'image_path': publicUrl,
          'caption': post.caption,
          'amount_vnd': post.amountVnd,
        });

        _log('Post insert success', details: {'attempt': attempt});
        onProgress?.call(1, 'Completed');
        return;
      } catch (error, stackTrace) {
        _log(
          'Create post failed',
          details: {
            'attempt': attempt,
            'hasFilePath': filePath != null,
            'error': error.toString(),
          },
          error: error,
          stackTrace: stackTrace,
        );

        if (filePath != null) {
          try {
            await client.storage.from('post_images').remove([filePath]);
            _log('Cleanup success', details: {
              'attempt': attempt,
              'path': filePath,
            });
          } catch (_) {
            // Best-effort cleanup for partially failed attempts.
          }
        }

        if (attempt == maxAttempts) {
          throw Exception(_mapCreatePostError(error));
        }

        onProgress?.call(0.1, 'Retrying upload ($attempt/$maxAttempts)...');
      }
    }
  }

  void _log(
    String message, {
    Map<String, Object?>? details,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final detailsText = details == null || details.isEmpty
        ? ''
        : details.entries.map((entry) => '${entry.key}=${entry.value}').join(', ');
    final combined = detailsText.isEmpty ? message : '$message | $detailsText';

    developer.log(
      combined,
      name: 'FeedPostRemoteDataSource',
      error: error,
      stackTrace: stackTrace,
    );

    if (error != null) {
      developer.log(
        'Create post error: $error',
        name: 'FeedPostRemoteDataSource',
      );
    }
  }

  Future<void> revealPost(String postId) async {
    final client = _client;
    if (client == null) throw Exception('Supabase is not configured.');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    await client
        .from('posts')
        .update({'is_revealed': true})
        .eq('id', postId)
        .eq('user_id', user.id);
  }

  String _mapCreatePostError(Object error) {
    final text = error.toString();

    if (text.contains('404')) {
      if (text.contains('post_images')) {
        return 'Upload failed (404): bucket post_images not found. Create bucket post_images in Supabase Storage first.';
      }
      if (text.contains('posts')) {
        return 'Save post failed (404): table posts not found. Run sql/supabase_init.sql in Supabase SQL Editor.';
      }
      return 'Post failed (404): endpoint/resource not found. Re-check Supabase Storage bucket and database schema.';
    }

    if (text.contains('401') || text.contains('403')) {
      return 'Permission denied while posting. Re-check Supabase RLS/storage policies and ensure account is signed in.';
    }

    return text;
  }
}
