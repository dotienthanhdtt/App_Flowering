import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Firebase configuration generated from GoogleService-Info.plist.
/// Re-generate with FlutterFire CLI if project settings change.
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkAKe5avwUaNOXnS70eD82jRnyrOlchrM',
    appId: '1:898715197112:ios:e6dda7e85a9f8f60011e4d',
    messagingSenderId: '898715197112',
    projectId: 'flowering-74b9e',
    storageBucket: 'flowering-74b9e.firebasestorage.app',
    iosBundleId: 'com.flowering.app',
    iosClientId:
        '898715197112-igsgcfq3chp3a1k9akkoph87aab0fdkt.apps.googleusercontent.com',
  );

  // TODO: Add Android config from google-services.json when available
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdRjCVZlhrq72RuEklEyyxYlBRCYhI2Sw',
    appId: '1:406099696497:android:0d4ed619c031c0ac3574d0',
    messagingSenderId: '898715197112',
    projectId: 'flowering-74b9e',
    storageBucket: 'flowering-74b9e.firebasestorage.app',
  );
}
