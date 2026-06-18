
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── WEB ─────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBhtEvSahK09PMVKGifcBaHS-sOvi8jhxY",
    authDomain: "student-task-82be2.firebaseapp.com",
    projectId: "student-task-82be2",
    storageBucket: "student-task-82be2.firebasestorage.app",
    messagingSenderId: "1066053602262",
    appId: "1:1066053602262:web:eb7c2efe96b0dbabea3277",
    measurementId: "G-8WJYZB5DBK",
  );

  // ── ANDROID ───────────────────────────────────────────────────────────────
  
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBhtEvSahK09PMVKGifcBaHS-sOvi8jhxY",
    authDomain: "student-task-82be2.firebaseapp.com",
    projectId: "student-task-82be2",
    storageBucket: "student-task-82be2.firebasestorage.app",
    messagingSenderId: "1066053602262",
    appId: "1:1066053602262:web:eb7c2efe96b0dbabea3277",
  );

  // ── iOS ───────────────────────────────────────────────────────────────────
  
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBhtEvSahK09PMVKGifcBaHS-sOvi8jhxY",
    authDomain: "student-task-82be2.firebaseapp.com",
    projectId: "student-task-82be2",
    storageBucket: "student-task-82be2.firebasestorage.app",
    messagingSenderId: "1066053602262",
    appId: "1:1066053602262:web:eb7c2efe96b0dbabea3277",
  );
}