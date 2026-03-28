import UIKit
import Flutter
// Rimuoviamo gli import diretti di Firebase se danno errore e usiamo solo:
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Registrazione standard automatica (ora che abbiamo pulito i Pods dovrebbe andare)
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}