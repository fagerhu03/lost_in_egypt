import UIKit
import Flutter
import GoogleMaps // 1. Imports the Google Maps library

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. Replace the text below with your actual Google Maps API key
    GMSServices.provideAPIKey("AIzaSyCxjOnbQ1BgmbNUWe-6iso8vKJrcjfGTqA")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
