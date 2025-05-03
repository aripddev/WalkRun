import CoreLocation
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var locations: [CLLocation]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)

        // Remove existing overlays
        uiView.removeOverlays(uiView.overlays)

        // Draw polyline for the path
        let coordinates = locations.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)

        // Center the map on the current location
        if let lastLocation = locations.last {
            region.center = lastLocation.coordinate
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        NavigationView {
            VStack {
                MapView(region: $region, locations: $locationManager.locations)
                    .frame(height: 300)

                if let currentLocation = locationManager.locations.last {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Position")
                            .font(.headline)
                            .foregroundColor(.blue)
                        LocationRow(location: currentLocation)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding()
                }

                List {
                    ForEach(Array(locationManager.locations.reversed().enumerated()), id: \.offset) { index, location in
                        LocationRow(location: location)
                    }
                }

                Spacer()

                Button(action: {
                    if locationManager.isTracking {
                        locationManager.stopTracking()
                    } else {
                        locationManager.startTracking()
                    }
                }) {
                    Text(locationManager.isTracking ? "Stop Tracking" : "Start Tracking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(locationManager.isTracking ? Color.red : Color.green)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("WalkRun")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}

struct LocationRow: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(location.timestamp)")
                .font(.caption)
                .foregroundColor(.gray)
            Text("Latitude: \(location.coordinate.latitude)")
            Text("Longitude: \(location.coordinate.longitude)")
            Text("Speed: \(String(format: "%.2f", location.speed * 3.6)) km/h")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
}
