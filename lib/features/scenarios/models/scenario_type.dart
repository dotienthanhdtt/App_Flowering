/// Origin/type of a scenario. Backend values: 'default' | 'kol'.
/// `default` collides with Dart's reserved keyword, so the enum case is
/// named `defaultType` and serialized via [apiValue].
enum ScenarioType {
  defaultType,
  kol;

  static ScenarioType fromString(String? raw) {
    switch (raw) {
      case 'kol':
        return ScenarioType.kol;
      default:
        return ScenarioType.defaultType;
    }
  }

  String get apiValue {
    switch (this) {
      case ScenarioType.defaultType:
        return 'default';
      case ScenarioType.kol:
        return 'kol';
    }
  }
}
