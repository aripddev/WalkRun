import SwiftUI
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingExportSheet = false
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data")) {
                    Button(action: {
                        locationManager.exportToGPX()
                        showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export GPX")
                        }
                    }
                    .disabled(locationManager.locations.isEmpty)
                    
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Data")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(locationManager.locations.isEmpty)
                }
                
                Section(header: Text("Integrations")) {
                    NavigationLink(destination: StravaSettingsView()) {
                        HStack {
                            Image(systemName: "figure.run")
                            Text("Strava Settings")
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                if let url = locationManager.gpxFileURL {
                    DocumentPicker(url: url)
                }
            }
            .alert("Clear All Data", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    locationManager.clearAllData()
                }
            } message: {
                Text("This will delete all recorded locations and stop tracking. This action cannot be undone.")
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url])
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
} 