import SwiftUI

struct StravaSettingsView: View {
    @StateObject private var stravaManager = StravaManager.shared
    @EnvironmentObject var locationManager: LocationManager
    @State private var activityName = ""
    @State private var showingNameAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Strava Integration")) {
                    if stravaManager.isAuthenticated {
                        HStack {
                            Text("Connected to Strava")
                            Spacer()
                            Button("Disconnect") {
                                stravaManager.logout()
                            }
                            .foregroundColor(.red)
                        }
                        
                        if let lastSync = stravaManager.lastSyncDate {
                            Text("Last synced: \(lastSync.formatted())")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Button("Connect to Strava") {
                            stravaManager.authenticate()
                        }
                    }
                }
                
                if stravaManager.isAuthenticated {
                    Section(header: Text("Upload Activity")) {
                        Button("Upload Current Activity") {
                            if locationManager.locations.isEmpty {
                                errorMessage = "No locations recorded. Please start tracking before uploading."
                                showingErrorAlert = true
                                return
                            }
                            showingNameAlert = true
                        }
                        .disabled(stravaManager.isLoading)
                        
                        if stravaManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
            }
            .navigationTitle("Strava Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert("Name Your Activity", isPresented: $showingNameAlert) {
                TextField("Activity Name", text: $activityName)
                Button("Cancel", role: .cancel) { }
                Button("Upload") {
                    stravaManager.uploadActivity(
                        locations: locationManager.locations,
                        name: activityName.isEmpty ? "WalkRun Activity" : activityName
                    ) { success, error in
                        if let error = error {
                            errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        } else if success {
                            activityName = ""
                        }
                    }
                }
            } message: {
                Text("Enter a name for your activity")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}