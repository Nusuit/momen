class PostAlias {
  PostAlias._();

  static const List<String> _adjectives = [
    'Shadow',
    'Silent',
    'Misty',
    'Drift',
    'Cloud',
    'Nova',
    'Echo',
    'Glint',
    'Frost',
    'Pixel',
  ];

  static const List<String> _nouns = [
    'Fox',
    'Owl',
    'Comet',
    'Wave',
    'Spark',
    'Bloom',
    'Rain',
    'Moon',
    'Dawn',
    'Pebble',
  ];

  static String fromPostId(String postId) {
    final normalized = postId.trim();
    if (normalized.isEmpty) {
      return 'Anon';
    }

    var hash = 2166136261;
    for (var i = 0; i < normalized.length; i++) {
      hash ^= normalized.codeUnitAt(i);
      hash = (hash * 16777619) & 0x7fffffff;
    }

    final adjective = _adjectives[hash % _adjectives.length];
    final noun = _nouns[(hash ~/ _adjectives.length) % _nouns.length];
    final number = (hash % 900) + 100;
    return '$adjective-$noun-$number';
  }
}
