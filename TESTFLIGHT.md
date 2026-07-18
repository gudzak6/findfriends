# TestFlight upload checklist

Bundle ID: `gudzak6.findfriends`  
Team: `TUWBYL2SX9`  
Version: `1.0.0` (build `1`)

## Required before upload (April 2026+)

App Store Connect **rejects** builds made with older SDKs.

| Requirement | Your machine now | Needed |
|---|---|---|
| Xcode | **16.2** | **Xcode 26+** |
| iOS SDK | **18.2** | **iOS 26 SDK** |

1. Install **Xcode 26** from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835) or [Apple Developer downloads](https://developer.apple.com/download/applications/)
2. Xcode 26 may require a newer macOS — update macOS first if the App Store blocks the install
3. Open the project in Xcode 26 → let packages resolve → **Product → Archive** → upload again

Your **deployment target** can stay at iOS 18 (or lower). Only the *build SDK* must be 26.

### Firebase “Upload Symbols Failed” messages

Those dSYM warnings for Firebase/Google frameworks are common with SwiftPM binary XCFrameworks. They usually **do not block** the upload. The hard failure is the SDK version. After you upload with Xcode 26, if symbols still warn, you can ignore them for TestFlight or later upload dSYMs from Firebase Crashlytics tooling if you add Crashlytics.

## Already configured in the Xcode project

- [x] Display name: **Find Friends**
- [x] App icon (1024×1024, no alpha)
- [x] Accent color
- [x] Location usage description (`NSLocationWhenInUseUsageDescription`)
- [x] Export compliance key (`ITSAppUsesNonExemptEncryption = NO` via build settings)
- [x] Privacy manifest (`PrivacyInfo.xcprivacy`) for location, email, phone, name, user ID, status text
- [x] Social Networking category
- [x] iPhone-only, portrait
- [x] Version `1.0.0` / build `1`
- [x] Firebase `GoogleService-Info.plist` in the app target
- [x] Automatic signing with your development team
- [x] Release configuration builds successfully

## One-time setup (you do this)

### 1. Apple Developer / App Store Connect

1. Sign in at [App Store Connect](https://appstoreconnect.apple.com)
2. **Apps → + → New App**
   - Platform: iOS
   - Name: Find Friends (or your preferred store name)
   - Bundle ID: select `gudzak6.findfriends` (create it under Certificates, Identifiers & Profiles if missing)
   - SKU: e.g. `findfriends-ios`
3. Under **Users and Access**, make sure your Apple ID can upload builds

### 2. Create the App ID (if needed)

1. [developer.apple.com](https://developer.apple.com) → **Identifiers** → **+**
2. App IDs → App
3. Bundle ID: `gudzak6.findfriends`
4. Capabilities: none required beyond defaults for this build (Push later if you add Buzz)

### 3. Archive & upload from Xcode

1. Open `findfriends.xcodeproj`
2. Select scheme **findfriends** → destination **Any iOS Device (arm64)**
3. Product → **Archive**
4. Organizer → **Distribute App** → **App Store Connect** → Upload
5. Wait for processing in App Store Connect → **TestFlight**

### 4. TestFlight compliance & testers

1. Open the build → answer export compliance if prompted (should be skipped because of Info.plist)
2. Add **Internal Testing** group (your team) or **External Testing** (needs Beta App Review)
3. For external testers, fill:
   - What to Test
   - Beta App Description
   - Contact email
   - Privacy Policy URL (required for external / App Store later)

### 5. Privacy policy (recommended now, required for App Store / external TestFlight)

Host a short page covering:

- Account email / name
- Optional phone number
- Location shared with friends
- Status messages
- Firebase as the service provider

Add the URL in App Store Connect → App Privacy / TestFlight.

## Before each new TestFlight build

1. Bump `CURRENT_PROJECT_VERSION` (build number) in Xcode — Apple rejects reuse of the same build
2. Optionally bump `MARKETING_VERSION` (e.g. 1.0.1)
3. Archive → Upload again

## Common upload failures

| Error | Fix |
|---|---|
| Missing app icon | Confirm `AppIcon.appiconset/AppIcon.png` exists |
| Invalid icon (alpha) | Icon must be opaque (already flattened) |
| Missing compliance | Confirm `ITSAppUsesNonExemptEncryption` is false |
| Bundle ID mismatch | App Store Connect app must use `gudzak6.findfriends` |
| Signing error | Xcode → Signing & Capabilities → Team selected; Paid Apple Developer Program |
| No GoogleService-Info | Keep `findfriends/GoogleService-Info.plist` in the target |

## Smoke test before inviting friends

1. Install TestFlight build on two phones
2. Create two accounts
3. Add friend via invite code
4. Confirm location + status sync
5. Confirm Message opens with phone number when set on Me
