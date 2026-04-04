import UIKit
import Flutter
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FirebaseApp.configure()

    // Usiamo il riferimento completo per forzare il compilatore
    SDK.GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// Se il compilatore fa ancora i capricci, aggiungiamo questa estensione in fondo al file
extension FlutterAppDelegate {
    func registerPlugins() {
        GeneratedPluginRegistrant.register(with: self)
    }
}