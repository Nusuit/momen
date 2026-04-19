import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/features/auth/presentation/state/friend_search_provider.dart';

void main() {
  test('friendSearchQueryProvider starts empty and updates value', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(friendSearchQueryProvider), '');

    container.read(friendSearchQueryProvider.notifier).setQuery('abc123');

    expect(container.read(friendSearchQueryProvider), 'abc123');
  });

  test('NearbySearchParams equality and hashCode are stable', () {
    const a = NearbySearchParams(lat: 10.0, lon: 106.0);
    const b = NearbySearchParams(lat: 10.0, lon: 106.0);
    const c = NearbySearchParams(lat: 10.1, lon: 106.0);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });
}
