part of 'auth_controller.dart';

// Social auth methods for AuthController.
// Declared as extension within the same library part — has access to all
// library-private (`_`) identifiers defined in auth_controller.dart.

extension AuthControllerSocial on AuthController {
  Future<void> signInWithGoogle() async {
    errorMessage.value = '';
    try {
      // serverClientId = Web Client ID (type 3) from google-services.json
      // Required on Android to receive an idToken from Google Sign-In
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
        serverClientId:
            '898715197112-g89g04i54mpeqcjau6ptpu6vn33iful0.apps.googleusercontent.com',
      );
      // No overlay during native picker — OS owns that UI
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user cancelled

      // Native picker closed with an account — show overlay during Firebase/API calls
      isLoading.value = true;
      _showLoadingOverlay();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _authenticateWithFirebase(credential);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = mapFirebaseAuthErrorCode(e.code).tr;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      errorMessage.value = 'google_sign_in_failed'.tr;
    } finally {
      isLoading.value = false;
      _hideLoadingOverlay();
    }
  }

  Future<void> signInWithApple() async {
    if (!Platform.isIOS) return;
    errorMessage.value = '';
    try {
      // No overlay during native picker — OS owns that UI
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Native picker closed with credentials — show overlay during Firebase/API calls
      isLoading.value = true;
      _showLoadingOverlay();
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _authenticateWithFirebase(oauthCredential);
    } on SignInWithAppleAuthorizationException {
      // user cancelled — do nothing
    } on FirebaseAuthException catch (e) {
      errorMessage.value = mapFirebaseAuthErrorCode(e.code).tr;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      errorMessage.value = 'apple_sign_in_failed'.tr;
    } finally {
      isLoading.value = false;
      _hideLoadingOverlay();
    }
  }

  void _showLoadingOverlay() {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      const Center(child: LoadingWidget()),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  void _hideLoadingOverlay() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  /// Signs in to Firebase, gets ID token, then calls backend /auth/firebase.
  Future<void> _authenticateWithFirebase(AuthCredential credential) async {
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) {
      errorMessage.value = 'firebase_token_error'.tr;
      return;
    }
    final response = await _apiClient.post<AuthResponse>(
      ApiEndpoints.loginFirebase,
      data: {
        'id_token': idToken,
        'display_name': userCredential.user?.displayName,
        if (_conversationId != null) 'conversation_id': _conversationId,
      },
      fromJson: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
    if (response.isSuccess && response.data != null) {
      await _handleAuthSuccess(response.data!);
    } else {
      errorMessage.value = response.message;
    }
  }
}
