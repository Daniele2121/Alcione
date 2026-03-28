import UIKit
import Flutter
import FirebaseCore
import FirebaseFirestore
import firebase_auth
import firebase_messaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    // Registriamo i plugin manualmente per evitare l'errore del GeneratedPluginRegistrant
    FLTFirebaseCorePlugin.register(with: self.registrar(forPlugin: "FLTFirebaseCorePlugin")!)
    FLTFirebaseFirestorePlugin.register(with: self.registrar(forPlugin: "FLTFirebaseFirestorePlugin")!)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}