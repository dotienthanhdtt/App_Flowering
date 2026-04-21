part of 'storage_service.dart';

// Preferences and permanent-flag methods for StorageService.
// Declared as extension within the same library part — has access to all
// library-private (`_`) identifiers defined in storage_service.dart.

extension StorageServicePreferences on StorageService {
  // ─────────────────────────────────────────────────────────────────
  // Permanent flags (survive clearAll)
  // ─────────────────────────────────────────────────────────────────

  /// True once the user has successfully logged in at least once.
  /// Never cleared — even after logout — so the app knows to show auth
  /// on the onboarding intro screens instead of routing into onboarding flows.
  bool get hasCompletedLogin =>
      getPreference<bool>(StorageService._hasCompletedLoginKey) ?? false;

  Future<void> setHasCompletedLogin() async =>
      setPreference<bool>(StorageService._hasCompletedLoginKey, true);

  /// Clear everything — used on logout.
  /// Preserves [StorageService._hasCompletedLoginKey] so returning users are never re-onboarded.
  Future<void> clearAll() async {
    final hadLogin = hasCompletedLogin;
    await clearAllCaches();
    await clearPreferences();
    if (hadLogin) await setHasCompletedLogin();
  }

  /// Returns all preference keys matching [test].
  Iterable<String> preferenceKeysMatching(bool Function(String) test) =>
      _preferences.keys.whereType<String>().where(test);

  /// Deletes all preference keys matching [test].
  Future<void> removePreferencesMatching(bool Function(String) test) async {
    final keys = preferenceKeysMatching(test).toList();
    for (final k in keys) {
      await _preferences.delete(k);
    }
  }
}
