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
   - Authorization Callback Domain: `walkrun`
3. Set up environment variables in Xcode:
   - Open the project in Xcode
   - Click on the scheme selector (next to the run/stop buttons)
   - Select "Edit Scheme..."
   - Select "Run" from the left sidebar
   - Select the "Arguments" tab
   - Under "Environment Variables", add:
     - `STRAVA_CLIENT_ID` = your Strava Client ID
     - `STRAVA_CLIENT_SECRET` = your Strava Client Secret
     - `STRAVA_REDIRECT_URI` = your Strava Redirect Uri

### Installation

1. Clone the repository
2. Open `WalkRun.xcodeproj` in Xcode
3. Set up the environment variables as described above
4. Build and run the app

## Usage

1. Start tracking your activity by tapping "Start Tracking"
2. Your location will be recorded in the background
3. Stop tracking when you're done
4. Export your activity as a GPX file or sync it with Strava

## Privacy

WalkRun requires location access to track your activities. Your location data is stored locally on your device and is only shared with Strava if you choose to sync your activities.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 