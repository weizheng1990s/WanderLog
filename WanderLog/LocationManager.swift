import Combine
import CoreLocation
import SwiftUI

final class LocationManager: NSObject, ObservableObject {

    static let shared = LocationManager()

    @Published var city: String = ""
    @Published var country: String = ""
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating: Bool = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        print("📍 requestLocation called, status: \(manager.authorizationStatus.rawValue)")
        city = ""
        country = ""
        isLocating = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            print("📍 Location denied")
            isLocating = false
        @unknown default:
            isLocating = false
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
                DispatchQueue.main.async { self?.isLocating = false }
                return
            }
            DispatchQueue.main.async {
                self.city = placemark.locality ?? ""
                self.country = placemark.country ?? ""
                self.coordinate = location.coordinate
                self.isLocating = false
                print("📍 City: \(self.city), Country: \(self.country)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")
        DispatchQueue.main.async { self.isLocating = false }
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
