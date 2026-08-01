import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBW9ACEYz7hD_CY-AtlG00rbIPwofoKU4o',
    appId: '1:553968357552:web:715b7412f7162634e0ab75', // Dummy web app ID format
    messagingSenderId: '553968357552',
    projectId: 'mitra-umkm',
    authDomain: 'mitra-umkm.firebaseapp.com',
    storageBucket: 'mitra-umkm.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBW9ACEYz7hD_CY-AtlG00rbIPwofoKU4o',
    appId: '1:553968357552:android:eb0fe2181a407406e0ab75',
    messagingSenderId: '553968357552',
    projectId: 'mitra-umkm',
    storageBucket: 'mitra-umkm.firebasestorage.app',
  );
}
