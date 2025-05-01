import Foundation
import AuthenticationServices
import CoreLocation

class StravaManager: NSObject, ObservableObject {
    static let shared = StravaManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    
    private let clientId = EnvironmentValues.stravaClientId
    private let clientSecret = EnvironmentValues.stravaClientSecret
    private let redirectUri = EnvironmentValues.stravaRedirectUri
    private let authUrl = "https://www.strava.com/oauth/authorize"
    private let tokenUrl = "https://www.strava.com/oauth/token"
    private let apiUrl = "https://www.strava.com/api/v3"
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpirationDate: Date?
    
    private override init() {
        super.init()
        loadTokens()
    }
    
    private func loadTokens() {
        if let token = UserDefaults.standard.string(forKey: "stravaAccessToken"),
           let refresh = UserDefaults.standard.string(forKey: "stravaRefreshToken"),
           let expiration = UserDefaults.standard.object(forKey: "stravaTokenExpiration") as? Date {
            accessToken = token
            refreshToken = refresh
            tokenExpirationDate = expiration
            isAuthenticated = true
        }
    }
    
    private func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        UserDefaults.standard.set(accessToken, forKey: "stravaAccessToken")
        UserDefaults.standard.set(refreshToken, forKey: "stravaRefreshToken")
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        UserDefaults.standard.set(expirationDate, forKey: "stravaTokenExpiration")
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpirationDate = expirationDate
        self.isAuthenticated = true
    }
    
    func authenticate() {
        let scope = "activity:write"
        let encodedRedirectUri = redirectUri.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? redirectUri
        let urlString = "\(authUrl)?client_id=\(clientId)&redirect_uri=\(encodedRedirectUri)&response_type=code&scope=\(scope)"
        
        if let url = URL(string: urlString) {
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "walkrun") { callbackURL, error in
                if let error = error {
                    print("Authentication error: \(error.localizedDescription)")
                    return
                }
                
                if let callbackURL = callbackURL,
                   let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
                    self.exchangeCodeForToken(code: code)
                }
            }
            
            session.presentationContextProvider = self
            session.start()
        }
    }
    
    private func exchangeCodeForToken(code: String) {
        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        var request = URLRequest(url: URL(string: tokenUrl)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Token exchange error: \(error.localizedDescription)")
                return
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String,
               let refreshToken = json["refresh_token"] as? String,
               let expiresIn = json["expires_in"] as? Int {
                DispatchQueue.main.async {
                    self.saveTokens(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
                }
            }
        }.resume()
    }
    
    func uploadActivity(locations: [CLLocation], name: String, type: String = "Run", completion: @escaping (Bool, Error?) -> Void) {
        guard isAuthenticated, let token = accessToken else {
            completion(false, NSError(domain: "StravaManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated with Strava"]))
            return
        }
        
        isLoading = true
        
        // Convert locations to GPX format
        let gpxData = generateGPXData(locations: locations)
        
        // Create multipart form-data request
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "\(apiUrl)/uploads")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add name field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(name)\r\n".data(using: .utf8)!)
        
        // Add type field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(type)\r\n".data(using: .utf8)!)
        
        // Add data_type field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"data_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("gpx\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"activity.gpx\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/gpx+xml\r\n\r\n".data(using: .utf8)!)
        body.append(gpxData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    completion(false, error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        self.lastSyncDate = Date()
                        completion(true, nil)
                    } else {
                        var errorMessage = "Upload failed with status code: \(httpResponse.statusCode)"
                        if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                            errorMessage += "\nResponse: \(responseBody)"
                        }
                        let error = NSError(domain: "StravaManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        completion(false, error)
                    }
                } else {
                    let error = NSError(domain: "StravaManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected response from server"])
                    completion(false, error)
                }
            }
        }.resume()
    }
    
    private func generateGPXData(locations: [CLLocation]) -> Data {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="WalkRun">
        <trk>
        <name>WalkRun Activity</name>
        <trkseg>
        """
        
        for location in locations {
            let timestamp = dateFormatter.string(from: location.timestamp)
            gpxString += """
            <trkpt lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
            <time>\(timestamp)</time>
            </trkpt>
            """
        }
        
        gpxString += """
        </trkseg>
        </trk>
        </gpx>
        """
        
        return gpxString.data(using: .utf8)!
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "stravaAccessToken")
        UserDefaults.standard.removeObject(forKey: "stravaRefreshToken")
        UserDefaults.standard.removeObject(forKey: "stravaTokenExpiration")
        
        accessToken = nil
        refreshToken = nil
        tokenExpirationDate = nil
        isAuthenticated = false
        lastSyncDate = nil
    }
}

extension StravaManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}