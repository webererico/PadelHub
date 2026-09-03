// Placeholder generated file — replace by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
// This regenerates this file with the real API keys/app IDs for each
// platform from your Firebase project. Do not hand-edit the values below.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for this platform. '
          'Run `flutterfire configure` to generate real options.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAGTwDWr9_WTvEZpnmJpefzVMeAUAO3fFI',
    appId: '1:1078280643284:web:cd3262e6c01027d9bb9141',
    messagingSenderId: '1078280643284',
    projectId: 'padelhub-e2b5f',
    authDomain: 'padelhub-e2b5f.firebaseapp.com',
    storageBucket: 'padelhub-e2b5f.firebasestorage.app',
    measurementId: 'G-S88CKQ0LJX',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    projectId: 'padelhub-prod',
    storageBucket: 'padelhub-prod.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    projectId: 'padelhub-prod',
    storageBucket: 'padelhub-prod.appspot.com',
    iosBundleId: 'com.padelhub.app',
  );
}
