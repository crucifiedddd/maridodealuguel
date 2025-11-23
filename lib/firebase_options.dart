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
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyC8cSnXoxGjvmkYewODMadcnfDR_s9k8Wk',
    appId: '1:577101206591:web:b7cfa66a860fddae1f148a',
    messagingSenderId: '577101206591',
    projectId: 'marido-aluguel-tcc2-2025',
    authDomain: 'marido-aluguel-tcc2-2025.firebaseapp.com',
    storageBucket: 'marido-aluguel-tcc2-2025.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUhOeK6AR_tSOnBplvbIOILjcwxe-Ll9k',
    appId: '1:577101206591:android:be39513720ec39301f148a',
    messagingSenderId: '577101206591',
    projectId: 'marido-aluguel-tcc2-2025',
    storageBucket: 'marido-aluguel-tcc2-2025.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB8_zwGSrOc5LA8lUOOCJexyu5DdpvAe3k',
    appId: '1:577101206591:ios:a689ef9182743d771f148a',
    messagingSenderId: '577101206591',
    projectId: 'marido-aluguel-tcc2-2025',
    storageBucket: 'marido-aluguel-tcc2-2025.firebasestorage.app',
    iosClientId: '577101206591-jvssoe0ve1a0ngf2umrepu79gdr0jn9j.apps.googleusercontent.com',
    iosBundleId: 'com.example.maridoDeAluguel',
  );

}