import 'package:flutter_test/flutter_test.dart';
import 'package:momen/core/utils/post_alias.dart';

void main() {
  test('PostAlias.fromPostId is deterministic', () {
    final alias1 = PostAlias.fromPostId('post-123');
    final alias2 = PostAlias.fromPostId('post-123');

    expect(alias1, alias2);
  });

  test('PostAlias.fromPostId varies across post ids', () {
    final alias1 = PostAlias.fromPostId('post-123');
    final alias2 = PostAlias.fromPostId('post-456');

    expect(alias1 == alias2, isFalse);
  });

  test('PostAlias.fromPostId handles empty id', () {
    expect(PostAlias.fromPostId(''), 'Anon');
  });
}
