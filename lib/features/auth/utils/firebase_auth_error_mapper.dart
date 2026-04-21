/// Maps FirebaseAuthException error codes to stable translation keys.
/// Never exposes e.message — it may contain OAuth fragments or PII.
String mapFirebaseAuthErrorCode(String code) {
  switch (code) {
    case 'invalid-credential':
      return 'auth_error_invalid_credential';
    case 'user-disabled':
      return 'auth_error_user_disabled';
    case 'user-not-found':
      return 'auth_error_user_not_found';
    case 'wrong-password':
      return 'auth_error_wrong_password';
    case 'network-request-failed':
      return 'auth_error_network';
    case 'too-many-requests':
      return 'auth_error_too_many_requests';
    case 'account-exists-with-different-credential':
      return 'auth_error_account_exists_different_credential';
    case 'operation-not-allowed':
      return 'auth_error_operation_not_allowed';
    default:
      return 'auth_error_generic';
  }
}
