/// Access tier for a scenario. Backend values: 'free' | 'premium'.
enum ScenarioAccessTier {
  free,
  premium;

  static ScenarioAccessTier fromString(String? raw) {
    switch (raw) {
      case 'premium':
        return ScenarioAccessTier.premium;
      default:
        return ScenarioAccessTier.free;
    }
  }

  String get apiValue => name;
}
