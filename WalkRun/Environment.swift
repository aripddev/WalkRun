import Foundation
import SwiftUI

struct EnvironmentValues {
    var stravaClientId: String
    var stravaClientSecret: String
    var stravaRedirectUri: String
}

private struct StravaEnvironmentKey: EnvironmentKey {
    typealias Value = EnvironmentValues
    
    static var defaultValue: EnvironmentValues {
        EnvironmentValues(
            stravaClientId: ProcessInfo.processInfo.environment["STRAVA_CLIENT_ID"] ?? "YOUR_STRAVA_CLIENT_ID",
            stravaClientSecret: ProcessInfo.processInfo.environment["STRAVA_CLIENT_SECRET"] ?? "YOUR_STRAVA_CLIENT_SECRET",
            stravaRedirectUri: ProcessInfo.processInfo.environment["STRAVA_REDIRECT_URI"] ?? "YOUR_STRAVA_REDIRECT_URI"
        )
    }
}

extension EnvironmentValues {
    static var stravaClientId: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_ID") as? String, !value.isEmpty else {
            print("⚠️ Warning: STRAVA_CLIENT_ID not set in Info.plist")
            return "YOUR_STRAVA_CLIENT_ID"
        }
        return value
    }

    static var stravaClientSecret: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_SECRET") as? String, !value.isEmpty else {
            print("⚠️ Warning: STRAVA_CLIENT_SECRET not set in Info.plist")
            return "YOUR_STRAVA_CLIENT_SECRET"
        }
        return value
    }

    static var stravaRedirectUri: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "STRAVA_REDIRECT_URI") as? String, !value.isEmpty else {
            print("⚠️ Warning: STRAVA_REDIRECT_URI not set in Info.plist")
            return "YOUR_STRAVA_REDIRECT_URI"
        }
        return value
    }
}
