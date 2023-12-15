// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyADtAqoDwta-aLvUsSekb7CMYyPyvkuHK8',
    appId: '1:260278994796:web:d62cae148ea63a32245549',
    messagingSenderId: '260278994796',
    projectId: 'xclout-1',
    authDomain: 'xclout-1.firebaseapp.com',
    storageBucket: 'xclout-1.appspot.com',
    measurementId: 'G-D8JPVL64HE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkoDt80snQJlw1rAD0xjQRS_gbmm4fkS8',
    appId: '1:260278994796:android:4ea163ab607fbb18245549',
    messagingSenderId: '260278994796',
    projectId: 'xclout-1',
    storageBucket: 'xclout-1.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3TvGLLsjIYDCqFVqehwblGDU8pmLM6BM',
    appId: '1:260278994796:ios:664d6302610b74da245549',
    messagingSenderId: '260278994796',
    projectId: 'xclout-1',
    storageBucket: 'xclout-1.appspot.com',
    iosBundleId: 'info.habertech.xclout',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC3TvGLLsjIYDCqFVqehwblGDU8pmLM6BM',
    appId: '1:260278994796:ios:7d9af0298c87e9c4245549',
    messagingSenderId: '260278994796',
    projectId: 'xclout-1',
    storageBucket: 'xclout-1.appspot.com',
    iosBundleId: 'info.habertech.xclout.RunnerTests',
  );
}
