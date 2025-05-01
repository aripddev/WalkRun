# WalkRun

A simple iOS app for tracking walking and running activities with Strava integration.

## Features

- Track your walking and running activities
- Export activities as GPX files
- Sync activities with Strava
- Background location tracking

## Setup

### Prerequisites

- Xcode 14.0 or later
- iOS 16.0 or later
- A Strava API account

### Strava Integration Setup

1. Create a Strava API application at https://www.strava.com/settings/api
2. Set the following in your Strava API application settings:
   - Authorization Callback Domain: The domain name of your `redirect_uri`. For example, if your `redirect_uri` is `https://subdomain.example.com/strava/callback`, then the Authorization Callback Domain should be `subdomain.example.com`.

### Environment Variables

Instead of setting environment variables directly in Xcode, use the `Secrets.xcconfig` file for better security and maintainability. Follow these steps:

1. Duplicate the `Secrets.xcconfig.example` file and rename it to `Secrets.xcconfig`.
2. Open the `Secrets.xcconfig` file and set the following values:
   ```
   STRAVA_CLIENT_ID = your_strava_client_id
   STRAVA_CLIENT_SECRET = your_strava_client_secret
   STRAVA_REDIRECT_URI = your_strava_redirect_uri
   ```
3. Ensure `Secrets.xcconfig` is excluded from version control (already handled in `.gitignore`).
4. The app will automatically load these values from `Secrets.xcconfig` via `Info.plist`.

### Installation

1. Clone the repository
2. Open `WalkRun.xcodeproj` in Xcode
3. Set up the environment variables as described above
4. Build and run the app

## Usage

1. Tap "Start Tracking" to begin recording your activity.
2. Your location will be tracked in the background while the activity is ongoing.
3. Tap "Stop Tracking" when you finish your activity.
4. Export your activity as a GPX file for external use or backup.
5. Sync your activity with Strava by tapping "Sync with Strava" to upload it directly.

## Debugging

If you encounter issues with the `redirect_uri`, ensure the following:

- The `STRAVA_REDIRECT_URI` in your `Secrets.xcconfig` matches the value registered in the Strava Developer Portal.
- The `redirect_uri` is correctly encoded in the app. You can debug this by printing the resolved value in the app logs.

## Troubleshooting

### Common Errors

- **"invalid redirect_uri"**:
  - Ensure the `redirect_uri` in the Strava Developer Portal matches the value sent by the app.
  - Double-check the encoding of the `redirect_uri` in the app.
  - Verify that the `STRAVA_REDIRECT_URI` is correctly set in `Secrets.xcconfig` and referenced in `Info.plist`.

## Privacy

WalkRun requires location access to track your activities. Your location data is stored locally on your device and is only shared with Strava if you choose to sync your activities.

## License

This project is licensed under the MIT License - see the LICENSE file for details.