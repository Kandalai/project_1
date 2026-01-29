// Firebase configuration file generated for Rain Safe Navigator.
//
// Run the following command to generate this file:
// `flutterfire configure --project=your-project-id`
//
// This file contains Firebase configuration for different platforms.
// Update the values with your actual Firebase project credentials.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase options for use across all platforms.
/// Update these values from your Firebase Console:
/// https://console.firebase.google.com
class DefaultFirebaseOptions {
  /// Android Firebase configuration.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_nVPALldayMu7Co1LboSi-YalNJqhGgs',
    appId: '1:455844743685:android:64686f6e120fd2fcbfea6c',
    messagingSenderId: '455844743685',
    projectId: 'rain-safe-navigator',
    databaseURL: 'https://rain-safe-navigator.firebaseio.com',
    storageBucket: 'rain-safe-navigator.appspot.com',
  );

  /// iOS Firebase configuration.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_nVPALldayMu7Co1LboSi-YalNJqhGgs',
    appId: '1:455844743685:ios:64686f6e120fd2fcbfea6c',
    messagingSenderId: '455844743685',
    projectId: 'rain-safe-navigator',
    databaseURL: 'https://rain-safe-navigator.firebaseio.com',
    storageBucket: 'rain-safe-navigator.appspot.com',
    iosBundleId: 'com.example.rainSafeNavigator',
  );

  /// Web Firebase configuration (optional - add if you support web).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_nVPALldayMu7Co1LboSi-YalNJqhGgs',
    appId: '1:455844743685:web:64686f6e120fd2fcbfea6c',
    messagingSenderId: '455844743685',
    projectId: 'rain-safe-navigator',
    databaseURL: 'https://rain-safe-navigator.firebaseio.com',
    storageBucket: 'rain-safe-navigator.appspot.com',
    authDomain: 'rain-safe-navigator.firebaseapp.com',
  );

  /// Returns the appropriate Firebase options for the current platform.
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
        return ios; // Use iOS config for macOS
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}