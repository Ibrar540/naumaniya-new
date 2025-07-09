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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Demo Firebase Configuration - Replace with your actual Firebase project
  // To get your own configuration:
  // 1. Go to https://console.firebase.google.com/
  // 2. Create a new project or select existing one
  // 3. Go to Project Settings > General
  // 4. Scroll down to "Your apps" section
  // 5. Add web app and copy the configuration
  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAOLn4MdaHmO35gwBLFmdggURDBMemwNtQ',
    appId: 'YOUR_WEB_APP_ID', // Please update with your actual web appId
    messagingSenderId: '347584942521',
    projectId: 'naumaniya-school-management',
    authDomain: 'naumaniya-school-management.firebaseapp.com',
    storageBucket: 'naumaniya-school-management.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOLn4MdaHmO35gwBLFmdggURDBMemwNtQ',
    appId: '1:347584942521:android:89a237a41919120336a668',
    messagingSenderId: '347584942521',
    projectId: 'naumaniya-school-management',
    storageBucket: 'naumaniya-school-management.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOLn4MdaHmO35gwBLFmdggURDBMemwNtQ',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '347584942521',
    projectId: 'naumaniya-school-management',
    storageBucket: 'naumaniya-school-management.appspot.com',
    iosClientId: '',
    iosBundleId: '',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAOLn4MdaHmO35gwBLFmdggURDBMemwNtQ',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '347584942521',
    projectId: 'naumaniya-school-management',
    storageBucket: 'naumaniya-school-management.appspot.com',
    iosClientId: '',
    iosBundleId: '',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAOLn4MdaHmO35gwBLFmdggURDBMemwNtQ',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: '347584942521',
    projectId: 'naumaniya-school-management',
    storageBucket: 'naumaniya-school-management.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAOLn4MdaHmO35gwBLFmdggURDBMemwNtQ',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: '347584942521',
    projectId: 'naumaniya-school-management',
    storageBucket: 'naumaniya-school-management.appspot.com',
  );
} 