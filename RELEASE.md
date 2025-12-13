# Play Store Release Guide

## Prerequisites

1. **Google Play Console Account** - Sign up at https://play.google.com/console
2. **Java Development Kit (JDK)** - Required for keytool

## Step 1: Generate Upload Keystore

Run this command to create your upload keystore (keep this file safe - you cannot recover it!):

```bash
keytool -genkey -v -keystore ~/cyberfly-release-key.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias cyberfly
```

You'll be prompted for:
- Keystore password
- Key password  
- Your name, organization, city, state, country

**⚠️ IMPORTANT: Back up this keystore file securely! If lost, you cannot update your app.**

## Step 2: Configure Signing

1. Copy the example key properties file:
   ```bash
   cp android/key.properties.example android/key.properties
   ```

2. Edit `android/key.properties` with your actual values:
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=cyberfly
   storeFile=/Users/YOUR_USERNAME/cyberfly-release-key.jks
   ```

## Step 3: Update Version

Edit `pubspec.yaml` and increment the version:
```yaml
version: 1.0.0+1  # format: major.minor.patch+buildNumber
```

- **versionName** (1.0.0): Displayed to users
- **versionCode** (+1): Must increase with each Play Store upload

## Step 4: Build Release AAB (Android App Bundle)

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate Rust bridge bindings
flutter_rust_bridge_codegen generate

# Build release AAB for Play Store
flutter build appbundle --release
```

The output will be at:
`build/app/outputs/bundle/release/app-release.aab`

### Alternative: Build APK (for direct distribution)

```bash
flutter build apk --release --split-per-abi
```

Outputs at `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (most modern devices)
- `app-armeabi-v7a-release.apk` (older devices)
- `app-x86_64-release.apk` (emulators, rare devices)

## Step 5: Test Release Build

Before uploading, test the release build:

```bash
# Install release APK on connected device
flutter install --release

# Or install specific ABI
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Step 6: Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app or select existing
3. Go to **Release > Production** (or Testing track first)
4. Click **Create new release**
5. Upload your `app-release.aab`
6. Add release notes
7. Review and roll out

## Play Store Listing Requirements

### App Information
- **App name**: Cyberfly Node
- **Short description**: (max 80 chars) P2P mobile node for Cyberfly decentralized network
- **Full description**: (max 4000 chars)

### Graphics Assets Required
- **App icon**: 512x512 PNG (already in `android/app/src/main/res/`)
- **Feature graphic**: 1024x500 PNG
- **Screenshots**: 
  - Phone: 2-8 screenshots (16:9 or 9:16)
  - Tablet (7"): 1-8 screenshots (optional)
  - Tablet (10"): 1-8 screenshots (optional)

### Content Rating
Complete the content rating questionnaire in Play Console.

### Privacy Policy
Required for apps that:
- Request sensitive permissions
- Collect user data

Host your privacy policy and add the URL in Play Console.

## App Permissions Explanation

For Play Store review, prepare explanations for these permissions:

| Permission | Reason |
|------------|--------|
| `INTERNET` | Connect to P2P network |
| `ACCESS_NETWORK_STATE` | Check network connectivity |
| `FOREGROUND_SERVICE` | Run P2P node in background |
| `FOREGROUND_SERVICE_DATA_SYNC` | Sync data with peers |
| `WAKE_LOCK` | Keep node running while syncing |
| `POST_NOTIFICATIONS` | Show node status notifications |
| `RECEIVE_BOOT_COMPLETED` | Auto-start node after reboot |

## Troubleshooting

### Build Errors

If you get signing errors:
```bash
# Verify your keystore
keytool -list -v -keystore ~/cyberfly-release-key.jks
```

If you get R8/ProGuard errors, check `android/app/proguard-rules.pro`.

### App Rejected

Common reasons:
- Missing privacy policy
- Incomplete content rating
- Broken functionality
- Policy violations

## Google Play Policy Compliance

### Required Documents

1. **Privacy Policy** (`PRIVACY_POLICY.md`)
   - Host this on your website (e.g., https://cyberfly.io/privacy)
   - Add URL in Play Console → Policy → App content → Privacy policy

2. **Data Safety** (`GOOGLE_PLAY_DATA_SAFETY.md`)
   - Follow guide to fill out Play Console → Policy → App content → Data safety

### Permission Declarations

When asked about sensitive permissions in Play Console:

**Foreground Service (DATA_SYNC)**:
> Required for continuous P2P network node operation. The app synchronizes distributed data with peers using gossip protocol and must maintain persistent connections to participate in the decentralized network.

**Boot Completed**:
> Optional feature allowing users to auto-start their node after device reboot for continuous network availability.

### Content Rating

Complete the IARC questionnaire. Recommended rating: **Everyone**
- No user-generated content
- No violence, profanity, or mature content
- Technical P2P app, not social networking

### App Category

- **Category**: Tools or Communication
- **Tags**: Cryptocurrency, Blockchain, P2P, Decentralized

## Useful Commands

```bash
# Check APK size
ls -lh build/app/outputs/flutter-apk/

# Analyze APK contents
flutter build apk --analyze-size

# Check signing of built APK
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk

# Generate native debug symbols for crash reporting
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```
