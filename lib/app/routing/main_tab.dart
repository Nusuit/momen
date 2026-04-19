enum MainTab { memories, social, camera, profile }

extension MainTabX on MainTab {
  String get routeName => switch (this) {
        MainTab.memories => 'memories',
      MainTab.social => 'social',
        MainTab.camera => 'camera',
        MainTab.profile => 'profile',
      };

  Map<String, String> get pathParameters => {'tab': routeName};

  static MainTab fromRouteName(String? routeName) {
    return MainTab.values.firstWhere(
      (tab) => tab.routeName == routeName,
      orElse: () => MainTab.camera,
    );
  }
}
