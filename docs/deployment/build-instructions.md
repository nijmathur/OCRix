# Build and Deployment Instructions

## Overview

This document provides comprehensive instructions for building, testing, and deploying the Privacy Document Scanner app across different platforms.

## Prerequisites

### Development Environment

-   **Flutter SDK**: Version 3.4.1 or higher
-   **Dart SDK**: Included with Flutter
-   **Android Studio**: For Android development
-   **Xcode**: For iOS development (macOS only)
-   **VS Code**: Recommended IDE with Flutter extensions

### Platform-Specific Requirements

#### Android

-   **Android SDK**: API level 21+ (Android 5.0)
-   **Java Development Kit**: JDK 11 or higher
-   **Android Studio**: Latest stable version
-   **Android Emulator**: For testing

#### iOS

-   **macOS**: Required for iOS development
-   **Xcode**: Version 14.0 or higher
-   **iOS Simulator**: For testing
-   **Apple Developer Account**: For App Store deployment

#### Web

-   **Chrome**: For testing and debugging
-   **Web Server**: For hosting (optional)

#### Desktop

-   **Windows**: Windows 10 or higher
-   **macOS**: macOS 10.14 or higher
-   **Linux**: Ubuntu 18.04 or higher

## Project Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd privacy_document_scanner
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Code

```bash
dart run build_runner build
```

### 4. Verify Setup

```bash
flutter doctor
```

## Build Configurations

### Debug Build

```bash
# Android
flutter build apk --debug

# iOS
flutter build ios --debug

# Web
flutter build web --debug

# Desktop
flutter build windows --debug
flutter build macos --debug
flutter build linux --debug
```

### Profile Build

```bash
# Android
flutter build apk --profile

# iOS
flutter build ios --profile

# Web
flutter build web --profile

# Desktop
flutter build windows --profile
flutter build macos --profile
flutter build linux --profile
```

### Release Build

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Google Cloud Console Setup

OCRix requires Google Sign-In for user authentication and Google Drive access. This section provides detailed setup instructions.

### Prerequisites

-   A Google Cloud Platform account
-   Access to [Google Cloud Console](https://console.cloud.google.com/)
-   Your app's package name: `com.ocrix.app`

### Step 1: Create a Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name (e.g., "OCRix")
4. Click "Create"
5. Wait for the project to be created and select it

### Step 2: Enable Required APIs

1. In the Google Cloud Console, navigate to **APIs & Services** → **Library**
2. Search for and enable the following APIs:
    - **Google Sign-In API** (or "Google Identity Toolkit API")
    - **Google Drive API**
3. Wait for the APIs to be enabled (may take a few moments)

### Step 3: Configure OAuth Consent Screen

1. Navigate to **APIs & Services** → **OAuth consent screen**
2. Choose **External** (unless you have a Google Workspace account)
3. Fill in the required information:
    - **App name**: OCRix (or your preferred name)
    - **User support email**: Your email address
    - **Developer contact information**: Your email address
4. Click **Save and Continue**
5. On the **Scopes** page, add the following scopes:
    - `.../auth/userinfo.email`
    - `.../auth/userinfo.profile`
    - `https://www.googleapis.com/auth/drive.file`
6. Click **Save and Continue** through the remaining steps
7. On the **Test users** page (if in testing mode), add test user emails if needed
8. Click **Save and Continue** → **Back to Dashboard**

### Step 4: Get SHA-1 Certificate Fingerprint

The SHA-1 fingerprint is required to link your app to the OAuth credentials. You need to get it for both debug and release builds.

#### For Debug Builds (Development/Testing):

**On macOS/Linux:**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**On Windows:**

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### For Release Builds (Production):

```bash
# Replace with your actual keystore path and alias
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

**Extracting the SHA-1:**

-   Look for the line that says `SHA1:` in the output
-   Copy the entire SHA-1 value (format: `AA:BB:CC:DD:EE:FF:...`)
-   Example: `A1:B2:C3:D4:E5:F6:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB`

### Step 5: Create OAuth 2.0 Client ID

1. Navigate to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Select **Android** as the application type
4. Fill in the form:
    - **Name**: "OCRix Android" (or any descriptive name)
    - **Package name**: `com.ocrix.app` (must match exactly)
    - **SHA-1 certificate fingerprint**: Paste the SHA-1 value from Step 4
5. Click **Create**
6. **Important**: You'll see a dialog with your Client ID - **you don't need to copy or hardcode this**. The app will automatically use it.

### Step 6: Add Additional SHA-1 Fingerprints (If Needed)

If you have multiple developers or need to support both debug and release builds:

1. Go to **APIs & Services** → **Credentials**
2. Click on your OAuth 2.0 Client ID
3. Click **+ ADD SHA-1 CERTIFICATE FINGERPRINT**
4. Add the additional SHA-1 fingerprint
5. Click **Save**

**Note**: You can add multiple SHA-1 fingerprints to the same OAuth client ID. This is useful when:

-   Different developers use different debug keystores
-   You need both debug and release SHA-1 fingerprints
-   CI/CD builds use different signing keys

### Step 7: Verify Configuration

1. **No Code Changes Required**: The `google_sign_in` package automatically detects and uses the OAuth credentials based on:

    - Your app's package name (`com.ocrix.app`)
    - The SHA-1 certificate fingerprint
    - The OAuth client ID configured in Google Cloud Console

2. **How It Works**:

    - When you build and run the app, the `google_sign_in` package queries Google's servers
    - Google matches your app's package name and SHA-1 fingerprint to the OAuth client ID
    - The correct Client ID is automatically used - no hardcoding needed

3. **Test the Configuration**:
    ```bash
    # Build and run the app
    flutter run
    # Try signing in with Google - it should work automatically
    ```

### Important Notes

-   **No Hardcoding Required**: The Client ID does **NOT** need to be hardcoded in the app code. The `google_sign_in` package handles this automatically.
-   **Package Name Must Match**: Ensure your `android/app/build.gradle` has `applicationId = "com.ocrix.app"` (or update the OAuth client ID to match your actual package name).
-   **SHA-1 Must Match Exactly**: The SHA-1 fingerprint must match exactly, including all colons (`:`).
-   **Debug vs Release**: If you test with debug builds and deploy release builds, add both SHA-1 fingerprints to the same OAuth client ID.

### Troubleshooting

#### "Sign in failed" or "OAuth client not found"

-   Verify the SHA-1 fingerprint matches exactly (copy-paste to avoid typos)
-   Ensure the package name matches exactly: `com.ocrix.app`
-   Check that the OAuth client ID is created for Android (not Web or iOS)
-   Wait a few minutes after creating credentials - Google's servers may need time to propagate

#### "API not enabled"

-   Go to **APIs & Services** → **Library**
-   Verify both "Google Sign-In API" and "Google Drive API" are enabled
-   If not enabled, click "Enable" and wait for activation

#### "Invalid client" error

-   Check that you're using the correct SHA-1 fingerprint for your build type (debug vs release)
-   Verify the OAuth consent screen is properly configured
-   Ensure you've added test users if the app is in testing mode

#### Multiple SHA-1 Fingerprints

-   You can add multiple SHA-1 fingerprints to the same OAuth client ID
-   This is the recommended approach for teams with multiple developers
-   Each developer's debug keystore will have a different SHA-1

## Platform-Specific Configuration

### Android Configuration

#### 1. Update android/app/build.gradle

```gradle
android {
    compileSdkVersion 34
    ndkVersion "25.1.8937393"

    defaultConfig {
        applicationId "com.privacy.documentscanner"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### 2. Configure Permissions (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### 3. Configure Signing

Create `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

### iOS Configuration

#### 1. Update ios/Runner/Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to import documents</string>
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure authentication</string>
```

#### 2. Configure Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project
3. Go to Signing & Capabilities
4. Select your development team
5. Configure bundle identifier

### Web Configuration

#### 1. Update web/index.html

```html
<!DOCTYPE html>
<html>
	<head>
		<base href="$FLUTTER_BASE_HREF" />
		<meta charset="UTF-8" />
		<meta content="IE=Edge" http-equiv="X-UA-Compatible" />
		<meta name="description" content="Privacy-first document scanner" />
		<meta name="apple-mobile-web-app-capable" content="yes" />
		<meta name="apple-mobile-web-app-status-bar-style" content="black" />
		<meta name="apple-mobile-web-app-title" content="Document Scanner" />
		<link rel="apple-touch-icon" href="icons/Icon-192.png" />
		<link rel="icon" type="image/png" href="favicon.png" />
		<title>Privacy Document Scanner</title>
		<link rel="manifest" href="manifest.json" />
	</head>
	<body>
		<script>
			window.flutterConfiguration = {
				canvasKitBaseUrl:
					"https://unpkg.com/canvaskit-wasm@0.33.0/bin/",
			};
		</script>
		<script src="flutter.js" defer></script>
	</body>
</html>
```

## Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Widget Tests

```bash
flutter test test/widget_test.dart
```

### Performance Testing

```bash
# Profile mode for performance testing
flutter run --profile
```

## Deployment

### Android Deployment

#### Google Play Store

1. **Build App Bundle**

    ```bash
    flutter build appbundle --release
    ```

2. **Upload to Play Console**
    - Go to Google Play Console
    - Create new release
    - Upload the generated `.aab` file
    - Fill in release notes and metadata
    - Submit for review

#### Direct APK Distribution

1. **Build APK**

    ```bash
    flutter build apk --release
    ```

2. **Distribute APK**
    - Share the generated `.apk` file
    - Users need to enable "Install from unknown sources"

### iOS Deployment

#### App Store

1. **Build for App Store**

    ```bash
    flutter build ios --release
    ```

2. **Archive in Xcode**
    - Open `ios/Runner.xcworkspace`
    - Select "Any iOS Device" as target
    - Product → Archive
    - Upload to App Store Connect

#### TestFlight

1. **Upload to TestFlight**
    - Use Xcode Organizer
    - Upload archive to App Store Connect
    - Configure TestFlight settings
    - Invite testers

### Web Deployment

#### Static Hosting

1. **Build Web App**

    ```bash
    flutter build web --release
    ```

2. **Deploy to Hosting Service**
    - Upload `build/web/` contents to hosting service
    - Configure HTTPS
    - Set up custom domain (optional)

#### Popular Hosting Options

-   **Firebase Hosting**: `firebase deploy`
-   **Netlify**: Drag and drop `build/web/` folder
-   **Vercel**: Connect GitHub repository
-   **GitHub Pages**: Push to `gh-pages` branch

### Desktop Deployment

#### Windows

1. **Build Windows App**

    ```bash
    flutter build windows --release
    ```

2. **Create Installer**
    - Use tools like Inno Setup or NSIS
    - Package the `build/windows/runner/Release/` folder
    - Create installer executable

#### macOS

1. **Build macOS App**

    ```bash
    flutter build macos --release
    ```

2. **Create DMG**
    - Use tools like create-dmg
    - Package the `.app` bundle
    - Create distributable DMG

#### Linux

1. **Build Linux App**

    ```bash
    flutter build linux --release
    ```

2. **Create Package**
    - Use tools like AppImage, Snap, or Flatpak
    - Package the `build/linux/x64/release/bundle/` folder
    - Create distributable package

## Continuous Integration/Continuous Deployment (CI/CD)

### GitHub Actions Example

#### .github/workflows/build.yml

```yaml
name: Build and Test

on:
    push:
        branches: [main, develop]
    pull_request:
        branches: [main]

jobs:
    test:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v3
            - uses: subosito/flutter-action@v2
              with:
                  flutter-version: "3.4.1"
            - run: flutter pub get
            - run: dart run build_runner build
            - run: flutter test

    build-android:
        needs: test
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v3
            - uses: subosito/flutter-action@v2
              with:
                  flutter-version: "3.4.1"
            - run: flutter pub get
            - run: dart run build_runner build
            - run: flutter build apk --release

    build-ios:
        needs: test
        runs-on: macos-latest
        steps:
            - uses: actions/checkout@v3
            - uses: subosito/flutter-action@v2
              with:
                  flutter-version: "3.4.1"
            - run: flutter pub get
            - run: dart run build_runner build
            - run: flutter build ios --release --no-codesign

    build-web:
        needs: test
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v3
            - uses: subosito/flutter-action@v2
              with:
                  flutter-version: "3.4.1"
            - run: flutter pub get
            - run: dart run build_runner build
            - run: flutter build web --release
```

## Environment Configuration

### Development Environment

```bash
# Set environment variables
export FLUTTER_ENV=development
export API_BASE_URL=https://dev-api.example.com
export LOG_LEVEL=debug
```

### Production Environment

```bash
# Set environment variables
export FLUTTER_ENV=production
export API_BASE_URL=https://api.example.com
export LOG_LEVEL=error
```

## Security Considerations

### Code Signing

-   **Android**: Use proper keystore for release builds
-   **iOS**: Use Apple Developer certificates
-   **Windows**: Consider code signing certificates
-   **macOS**: Use Apple Developer certificates

### App Security

-   **Obfuscation**: Enable code obfuscation for release builds
-   **Certificate Pinning**: Implement for API communications
-   **Root Detection**: Detect and handle rooted/jailbroken devices
-   **Debug Detection**: Disable debug features in release builds

### Data Protection

-   **Encryption**: Ensure all sensitive data is encrypted
-   **Secure Storage**: Use secure storage for sensitive information
-   **Network Security**: Use HTTPS for all network communications
-   **Key Management**: Implement secure key management

## Monitoring and Analytics

### Crash Reporting

```dart
// Add to main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Crashlytics
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(MyApp());
}
```

### Performance Monitoring

```dart
// Add performance monitoring
import 'package:firebase_performance/firebase_performance.dart';

Future<void> trackPerformance() async {
  final trace = FirebasePerformance.instance.newTrace('document_scan');
  await trace.start();

  // Your code here

  await trace.stop();
}
```

## Troubleshooting

### Common Build Issues

#### Android Build Issues

-   **Gradle Issues**: Clean and rebuild project
-   **SDK Issues**: Update Android SDK and build tools
-   **Permission Issues**: Check AndroidManifest.xml

#### iOS Build Issues

-   **Xcode Issues**: Update Xcode to latest version
-   **Signing Issues**: Check Apple Developer account and certificates
-   **Simulator Issues**: Reset iOS Simulator

#### Web Build Issues

-   **Canvas Kit Issues**: Check internet connection for Canvas Kit download
-   **CORS Issues**: Configure proper CORS headers
-   **Service Worker Issues**: Clear browser cache

### Performance Issues

-   **Memory Usage**: Monitor memory usage in profile mode
-   **Build Time**: Use incremental builds when possible
-   **App Size**: Optimize assets and dependencies

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**Status**: Complete
