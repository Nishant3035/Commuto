import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return android; // Using same config for now
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBkZT1gmnxayZZpMA-bv6xR1hmUewmsl4s',
    appId: '1:906498268429:web:f42f2ca85e4b409bb52444',
    messagingSenderId: '906498268429',
    projectId: 'commuto-for-students',
    authDomain: 'commuto-for-students.firebaseapp.com',
    storageBucket: 'commuto-for-students.firebasestorage.app',
    measurementId: 'G-1XM90Z9YDX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIufWlYIMDeSjguBRc0ROu1CfBoPVMk58',
    appId: '1:906498268429:android:55fbb8308577217eb52444',
    messagingSenderId: '906498268429',
    projectId: 'commuto-for-students',
    storageBucket: 'commuto-for-students.firebasestorage.app',
  );
}
