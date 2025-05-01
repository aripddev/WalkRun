import CoreLocation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        NavigationView {
            VStack {
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
