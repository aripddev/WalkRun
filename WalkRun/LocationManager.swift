import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var locations: [CLLocation] = []
    @Published var isTracking = false
    @Published var gpxFileURL: URL?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startTracking() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        isTracking = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
    }
    
    func clearAllData() {
        locations.removeAll()
        gpxFileURL = nil
        if isTracking {
            stopTracking()
        }
    }
    
    func exportToGPX() {
        guard !locations.isEmpty else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="WalkRun" xmlns="http://www.topografix.com/GPX/1/1">
        <trk>
        <name>WalkRun Track</name>
        <trkseg>
        """
        
        for location in locations {
            let timestamp = dateFormatter.string(from: location.timestamp)
            gpxString += """
            <trkpt lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
                <ele>\(location.altitude)</ele>
                <time>\(timestamp)</time>
                <speed>\(location.speed)</speed>
            </trkpt>
            """
        }
        
        gpxString += """
        </trkseg>
        </trk>
        </gpx>
        """
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("walkrun_track_\(Date().timeIntervalSince1970).gpx")
        
        do {
            try gpxString.write(to: fileURL, atomically: true, encoding: .utf8)
            gpxFileURL = fileURL
        } catch {
            print("Error writing GPX file: \(error)")
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.locations.append(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if isTracking {
                manager.startUpdatingLocation()
            }
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Location access not determined")
        @unknown default:
            print("Unknown authorization status")
        }
    }
}
