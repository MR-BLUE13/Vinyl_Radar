# VinylRadar (Phase 1)

SwiftUI-based Radar Feed scaffold for limited vinyl drop tracking.

## What is included
- iOS-first design tokens (dark mode first + light fallback)
- Radar feed with Header / Summary / Filter chips / Large cards
- Loading / Empty / Error states
- Detail page skeleton
- Mock repository + JSON resources
- Remote repository with local cache fallback
- Local wishlist persistence via `UserDefaults`
- Unit tests for mapper, filtering, sorting, wishlist, and relative time formatter

## Entry point
Use `VinylRadarRootView` from:
- `Sources/VinylRadar/App/VinylRadarRootView.swift`

## Open in Xcode (Demo App)
- Open `/Users/apple/Desktop/Vinyl/VinylRadarDemo/VinylRadarDemo.xcodeproj`
- Select scheme `VinylRadarDemo`
- Choose an iPhone simulator and run

The demo app already links the local package (`..`) and shows `VinylRadarRootView` as the root screen.

## Remote feed configuration
`VinylRadarRootView` now supports `RemoteRadarFeedRepository` out of the box.

- Preferred: set env var `RADAR_API_BASE_URL`
- Alternative: set `RadarAPIBaseURL` in app `Info.plist`

Expected endpoint:
- `GET /v1/radar/releases`
- response shape:
  - `generatedAt: ISO8601 string`
  - `releases: ReleaseDrop[]`

When remote fetch fails, the app falls back to:
1. local cached releases
2. mock releases (via repository fallback)

## Local backend (aggregator)
Repository now includes a lightweight backend at `backend/`.

Run:
```bash
python3 -m backend.app
```

One-shot refresh (no server bind):
```bash
python3 -m backend.app --once
```

Then configure app env:
- `RADAR_API_BASE_URL=http://127.0.0.1:8080`

## Run tests
```bash
swift test
```

## Notes
- This repository is currently a Swift Package module.  
  In Xcode, open `Package.swift` and embed `VinylRadarRootView` into your app target.
- Cover art uses `coverImageURL` first and falls back to generated gradients.
