import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY_FROM_FIREBASE_CONSOLE', // هتلاقيها في إعدادات المشروع في فيربيز
    appId: '1:619054778393:android:YOUR_APP_ID',
    messagingSenderId: '619054778393',
    projectId: 'mazadgame-6c295',
    storageBucket: 'mazadgame-6c295.appspot.com',
  );
}