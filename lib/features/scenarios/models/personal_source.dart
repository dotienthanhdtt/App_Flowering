/// Source that placed a scenario in the user's personal (For You) feed.
/// Backend values: 'personalized' | 'kol'.
enum PersonalSource {
  personalized,
  kol;

  static PersonalSource fromString(String? raw) {
    switch (raw) {
      case 'kol':
        return PersonalSource.kol;
      default:
        return PersonalSource.personalized;
    }
  }

  String get apiValue => name;
}
