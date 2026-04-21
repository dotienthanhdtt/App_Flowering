/// Per-user scenario status computed by backend.
/// Backend values: 'available' | 'locked' | 'learned'.
enum ScenarioUserStatus {
  available,
  locked,
  learned;

  static ScenarioUserStatus fromString(String? raw) {
    switch (raw) {
      case 'locked':
        return ScenarioUserStatus.locked;
      case 'learned':
        return ScenarioUserStatus.learned;
      default:
        return ScenarioUserStatus.available;
    }
  }

  String get apiValue => name;
}
