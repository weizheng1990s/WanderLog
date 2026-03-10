import CoreLocation
import SwiftUI

@Observable
final class LocationManager: NSObject {

    static let shared = LocationManager()

    var city: String = ""
    var country: String = ""
    var coordinate: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        print("📍 requestLocation called, status: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            print("📍 Location denied")
        @unknown default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        print("📍 Got location: \(location.coordinate)")
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self, let placemark = placemarks?.first else {
                print("📍 Geocode error: \(error?.localizedDescription ?? "nil")")
                return
            }
            DispatchQueue.main.async {
                self.city = placemark.locality ?? ""
                self.country = placemark.country ?? ""
                self.coordinate = location.coordinate
                print("📍 City: \(self.city), Country: \(self.country)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Auth changed: \(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
