import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// ⚠️  ACTION REQUIRED — PLATFORM PROJECT MISMATCH ⚠️
///
/// The Android and iOS configs below currently point to TWO DIFFERENT
/// Firebase projects:
///
///   Android → projectId: "erp-project-ba24f"  (messagingSenderId: 903789590606)
///   iOS     → projectId: "e-customer-dev"     (messagingSenderId: 981068595271)
///
/// This is almost certainly a copy-paste oversight. A backend that
/// targets one project's FCM topic CANNOT deliver pushes to users on
/// the other platform. Same problem for Crashlytics, Analytics, and
/// Remote Config — they're effectively two separate apps.
///
/// **Fix:** decide which project is canonical (probably
/// `erp-project-ba24f` since `main.dart` boots with the Android config
/// at index 0), then regenerate via:
///
///   ```
///   dart pub global activate flutterfire_cli
///   flutterfire configure --project=<canonical-project-id>
///   ```
///
/// That command writes the correct apiKey / appId / messagingSenderId
/// for EVERY platform pointing at the same Firebase project, plus the
/// optional `storageBucket`, `iosBundleId`, `iosClientId` fields
/// missing from the current hand-written config (Storage + APNS push
/// routing rely on those).
///
/// I have NOT modified the credentials here — those identify real
/// Firebase apps and I can't know which project you intended without
/// asking. Until this is fixed, iOS pushes will NOT reach your users
/// even after the rest of the notification stack is working.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions();

  /// Prod — Android (`erp-project-ba24f`)
  static const FirebaseOptions androidProd = FirebaseOptions(
    apiKey: "AIzaSyC9GQ_IAasLPrOhl4fflGjGGP3OPfAxcLQ",
    appId: "1:903789590606:android:f04c643b383b358673ab1f",
    messagingSenderId: "903789590606",
    projectId: "erp-project-ba24f",
  );

  /// Prod — iOS (`e-customer-dev`) ← WRONG PROJECT (see warning above).
  // static const FirebaseOptions iosProd = FirebaseOptions(
  //   apiKey: "AIzaSyB41yHhZ_eoTc2go0icMI5Yj74VvixPLeM",
  //   appId: "1:903789590606:ios:f0c38e800be8f28573ab1f",
  //   messagingSenderId: "903789590606",
  //   projectId: "erp-project-ba24f",
  // );

  /// new ios
  static const FirebaseOptions iosProd = FirebaseOptions(
    apiKey: "AIzaSyB41yHhZ_eoTc2go0icMI5Yj74VvixPLeM",
    appId: "1:903789590606:ios:63bb1fd6d44910ed73ab1f",
    messagingSenderId: "903789590606",
    projectId: "erp-project-ba24f",
  );
  FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidProd;
      case TargetPlatform.iOS:
        return iosProd;
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
}
