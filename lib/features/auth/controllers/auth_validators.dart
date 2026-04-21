import 'package:get/get.dart';

// Pure top-level validator functions — no controller state needed.
// Named with `Fn` suffix so AuthController can expose identically-named
// instance-method delegates without a name clash.

String? validateFullNameFn(String? v) {
  if (v == null || v.trim().isEmpty) return 'full_name_required'.tr;
  return null;
}

String? validateEmailFn(String? v) {
  if (v == null || v.trim().isEmpty) return 'email_required'.tr;
  if (!GetUtils.isEmail(v.trim())) return 'email_invalid'.tr;
  return null;
}

String? validatePasswordFn(String? v) {
  if (v == null || v.isEmpty) return 'password_required'.tr;
  if (v.length < 8) return 'password_min_length'.tr;
  return null;
}

String? validateConfirmPasswordFn(String? v, String password) {
  if (v != password) return 'passwords_not_match'.tr;
  return null;
}
