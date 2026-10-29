# Build Instructions

## Prerequisites
- **OS**: macOS 14 or later (verified on macOS 26)
- **Xcode**: 26.2 (any Xcode with the iOS 17 SDK and Swift 6 works); verified with Swift 6.2.3
- **Tuist**: 4.x (verified with 4.148.1)
- **Simulator runtime**: iOS 17.0 or later (verified on iOS 17.2, iPhone 15 Pro)
- **Dependencies**: none outside Apple frameworks; no package downloads needed
- **Environment variables**: none required
- **Disk**: about 1 GB for DerivedData

## Build Steps

### 1. Install tools
```bash
xcode-select --install          # if command-line tools are missing
mise use -g tuist@4             # or: brew install tuist
tuist version                   # → 4.x
```

### 2. Configure (optional, for device builds with sync)
Edit `Tuist/ProjectDescriptionHelpers/AppIdentifiers.swift`:
```swift
public static let developmentTeam = "ABCDE12345"   // your Team ID
```
Leaving it empty builds unsigned for the simulator, without iCloud or the App Group.

### 3. Generate the Xcode workspace
```bash
cd /Users/mmomo/Code/AIDLC/demo
tuist generate              # add --no-open for CI or headless use
```

### 4. Build all units
```bash
# Package units (Domain + Data) on the Mac host
cd JournalCore && swift build --build-tests && cd ..

# App + embedded widget for the simulator
xcodebuild -workspace DailyJournal.xcworkspace -scheme JournalApp \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

### 5. Verify build success
- **Expected output**: `Build complete!` (SwiftPM) and `** BUILD SUCCEEDED **` (xcodebuild), with 0 warnings
- **Artifacts**: `DerivedData/.../Build/Products/<Config>-iphonesimulator/JournalApp.app` containing `PlugIns/JournalWidget.appex` (Release about 5.9 MB)
- **Acceptable noise**: `DVTDeviceOperation: Encountered a build number "" …` log lines from xcodebuild are Xcode tooling messages, not build warnings

### 6. Run in the simulator
```bash
open -a Simulator
xcrun simctl install booted <path>/JournalApp.app
xcrun simctl launch booted com.mmomo.dailyjournal
```
Or press ⌘R in Xcode with the `JournalApp` scheme.

## Troubleshooting

### `Unable to find a device matching the provided destination specifier`
- **Cause**: the named simulator doesn't exist for the installed runtimes.
- **Solution**: run `xcrun simctl list devices available` and use `-destination 'platform=iOS Simulator,id=<UDID>'`, or `generic/platform=iOS Simulator` for a build without running.

### Tuist can't write its state directory (sandboxed shells)
- **Cause**: Tuist writes to `~/.local/state/tuist`.
- **Solution**: point the XDG folders somewhere writable: `XDG_STATE_HOME=/tmp/x XDG_CACHE_HOME=/tmp/x XDG_CONFIG_HOME=/tmp/x tuist generate`.

### Signing errors after setting a Team ID
- **Cause**: the App Group or iCloud container isn't registered for the team.
- **Solution**: in Xcode → target → Signing & Capabilities, let automatic signing register `group.com.mmomo.dailyjournal` and `iCloud.com.mmomo.dailyjournal` for both targets, then run `tuist generate` again.

### Compilation errors in Swift 6 mode
- **Cause**: a newer or older toolchain's concurrency diagnostics.
- **Solution**: use Xcode 26.x. The project uses `SWIFT_VERSION = 6.0` and `swiftLanguageModes: [.v6]`.
