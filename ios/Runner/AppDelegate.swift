import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {

  let locationManager = CLLocationManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    locationManager.delegate = self
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.startMonitoringSignificantLocationChanges()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }

    print("Significant Location Update: \(location.coordinate.latitude), \(location.coordinate.longitude)")

    UserDefaults.standard.set([
        "lat": location.coordinate.latitude,
        "lng": location.coordinate.longitude,
        "time": Date().timeIntervalSince1970
    ], forKey: "last_bg_location")
  }
}