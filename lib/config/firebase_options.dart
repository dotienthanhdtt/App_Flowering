import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

import 'env_config.dart';

/// Firebase configuration loaded from environment files.
/// Update `.env.dev` / `.env.prod` to change project settings.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: EnvConfig.firebaseIosApiKey,
        appId: EnvConfig.firebaseIosAppId,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        storageBucket: EnvConfig.firebaseStorageBucket,
        iosBundleId: EnvConfig.firebaseIosBundleId,
        iosClientId: EnvConfig.firebaseIosClientId,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: EnvConfig.firebaseAndroidApiKey,
        appId: EnvConfig.firebaseAndroidAppId,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        storageBucket: EnvConfig.firebaseStorageBucket,
        androidClientId: EnvConfig.firebaseAndroidClientId,
      );
}
