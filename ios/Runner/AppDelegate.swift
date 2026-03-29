import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Invece di chiamare direttamente GeneratedPluginRegistrant,
    // usiamo questo metodo più sicuro per le build da Windows
    if let registrantClass = NSClassFromString("GeneratedPluginRegistrant") as? NSObject.Type {
        let selector = NSSelectorFromString("registerWithRegistry:")
        if registrantClass.responds(to: selector) {
            registrantClass.perform(selector, with: self)
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}