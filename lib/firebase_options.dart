import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBAtlcGIxxPdnhjNaMlTi3Go3kCkj7V46g',
    authDomain: 'teamcloud-94b3a.firebaseapp.com',
    projectId: 'teamcloud-94b3a',
    storageBucket: 'teamcloud-94b3a.firebasestorage.app',
    messagingSenderId: '182394055959',
    appId: '1:182394055959:web:a17afb5629a4a5c6f4db52',
    measurementId: 'G-CGWXZLS45E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2oyhAhOn_RTI1-hflQ7hqs3z2ChqTOa8',
    appId: '1:182394055959:android:527afac466d602e3f4db52',
    messagingSenderId: '182394055959',
    projectId: 'teamcloud-94b3a',
    storageBucket: 'teamcloud-94b3a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjf5xo18AifGu_BAO8emLnA32bFHcWFsE',
    appId: '1:182394055959:ios:8aa3b7bea6a6da91f4db52',
    messagingSenderId: '182394055959',
    projectId: 'teamcloud-94b3a',
    storageBucket: 'teamcloud-94b3a.firebasestorage.app',
    iosBundleId: 'com.teamcloud.teamcloudNew',
  );
}
