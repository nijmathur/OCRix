# SHA1 Fingerprints for Google Sign-In

## Overview

Google Sign-In requires SHA1 fingerprints to verify your app. You need to configure BOTH debug and release fingerprints in Google Cloud Console.

## Understanding SHA1 Fingerprints

### What is a SHA1 Fingerprint?

A SHA1 fingerprint is a unique identifier derived from your app's signing certificate. It's used by Google to verify your app's identity.

**Key points:**
- SHA1 is derived from the **keystore certificate**, not the build
- Same keystore = same SHA1 (consistent across builds)
- Different keystores = different SHA1s

### Debug vs Release Fingerprints

| Build Type | Keystore | SHA1 | Consistency |
|------------|----------|------|-------------|
| **Debug** | `~/.android/debug.keystore` | Debug SHA1 | ✅ Same on your machine |
| **Release** | `upload-keystore.jks` | Release SHA1 | ✅ Same for all your releases |

**Important:** You need BOTH SHA1s configured for Google Sign-In to work in both debug and release modes.

## Step 1: Get Your Debug SHA1

```bash
# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Look for:
```
Certificate fingerprints:
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

## Step 2: Get Your Release SHA1

### If You Already Have a Keystore:

```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

Enter your keystore password when prompted.

### If You're Creating a New Keystore:

After generating the keystore (see `KEYSTORE_QUICKSTART.md`), run:

```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

## Step 3: Add Both SHA1s to Google Cloud Console

### 3.1: Open Google Cloud Console

1. Go to: https://console.cloud.google.com/
2. Select your project (e.g., "OCRix")
3. Navigate to: **APIs & Services → Credentials**

### 3.2: Find OAuth 2.0 Client ID

Look for: **OAuth 2.0 Client IDs** section

You should see:
- "Web client (auto created by Google Service)"
- Or your Android OAuth client

### 3.3: Add SHA1 Fingerprints

**For Android OAuth Client:**

1. Click on the Android OAuth client
2. Under **SHA-1 certificate fingerprints**, you should see your debug SHA1
3. Click **+ ADD FINGERPRINT**
4. Paste your **Release SHA1**
5. Click **SAVE**

**Result:** Now you have both:
```
SHA-1 certificate fingerprints:
- AA:BB:CC:... (Debug SHA1)
- XX:YY:ZZ:... (Release SHA1)
```

### 3.4: Verify Configuration

Your OAuth client should now have:
- **Package name:** `com.ocrix.app`
- **SHA-1 fingerprints:**
  - Debug SHA1 (for development)
  - Release SHA1 (for production)

## Step 4: Download Updated google-services.json

After adding the release SHA1:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Click gear icon ⚙️ → Project settings
4. Scroll to "Your apps" section
5. Find your Android app
6. Click **Download google-services.json**
7. Replace `android/app/google-services.json` with the new file

**Note:** The `google-services.json` file itself doesn't change, but it's good practice to refresh it.

## Step 5: Test Both Configurations

### Test Debug Build:

```bash
flutter run --debug
# Try Google Sign-In - should work with debug SHA1
```

### Test Release Build:

```bash
flutter build apk --release
# Install APK on device
adb install build/app/outputs/flutter-apk/app-release.apk
# Try Google Sign-In - should work with release SHA1
```

## Troubleshooting

### Error: "Google Sign-In failed" in Release Build

**Cause:** Release SHA1 not configured in Google Cloud Console.

**Solution:**
1. Get release SHA1: `keytool -list -v -keystore ~/upload-keystore.jks -alias upload`
2. Add to Google Cloud Console (Step 3)
3. Wait 5-10 minutes for changes to propagate
4. Rebuild and test

### Error: "Developer error" or "API not enabled"

**Cause:** Incorrect package name or SHA1 mismatch.

**Solution:**
1. Verify package name: `com.ocrix.app` (in `build.gradle`)
2. Verify SHA1 matches exactly (no extra spaces)
3. Check Firebase project settings match

### SHA1 Keeps Changing

**Cause:** Using different keystores for builds.

**Solution:**
- Debug builds: Always use `~/.android/debug.keystore`
- Release builds: Always use the same `upload-keystore.jks`
- Never delete or regenerate your keystore!

### Works Locally but Not in CI/CD

**Cause:** GitHub Actions using different keystore or no release SHA1.

**Solution:**
1. Verify GitHub secrets are set correctly (`KEYSTORE_BASE64`, etc.)
2. Check release SHA1 is added to Google Cloud Console
3. Verify keystore being decoded in CI matches your local keystore

## GitHub Actions Considerations

### Getting SHA1 from CI Build

The keystore in GitHub Actions (decoded from `KEYSTORE_BASE64`) should have the **same SHA1** as your local keystore because it's the same keystore file.

To verify SHA1 in CI (optional debug step):

```yaml
- name: Verify Release SHA1
  run: |
    keytool -list -v -keystore android/app/upload-keystore.jks \
      -storepass ${{ secrets.KEYSTORE_PASSWORD }} | grep SHA1
```

## Best Practices

### 1. Document Your SHA1s

Keep a record of your fingerprints:

```
Debug SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
Release SHA1: XX:YY:ZZ:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00
```

Store in:
- Password manager (with keystore info)
- Project documentation
- Team knowledge base

### 2. Backup Your Keystore

Your release SHA1 is tied to your keystore. If you lose the keystore:
- You lose the SHA1
- You must reconfigure Google Sign-In
- Users may have to reinstall app

**Backup locations:**
- Password manager
- Encrypted cloud storage
- Secure physical storage

### 3. Team Collaboration

If multiple team members build releases:
- Share the same `upload-keystore.jks` file (securely)
- All will have the same release SHA1
- Google Sign-In will work for all builds

### 4. Play App Signing

If using Google Play App Signing:
- Google re-signs your app with their key
- You need the **App signing certificate SHA1** from Play Console
- Add this SHA1 to Google Cloud Console as well

**Get Play App Signing SHA1:**
1. Go to Play Console → Your app → Setup → App integrity
2. Copy "SHA-1 certificate fingerprint" under "App signing key certificate"
3. Add to Google Cloud Console

## Quick Reference

### Get Debug SHA1:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

### Get Release SHA1:
```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload | grep SHA1
```

### Add SHA1 to Google Cloud Console:
1. https://console.cloud.google.com/
2. APIs & Services → Credentials
3. OAuth 2.0 Client → Add Fingerprint
4. Save

### Verify APK SHA1:
```bash
# Extract certificate from APK
unzip -p app-release.apk META-INF/*.RSA | keytool -printcert | grep SHA1
```

## Related Documentation

- [Google Sign-In Setup Guide](../features/google-drive/ENABLE_DRIVE_API.md)
- [Keystore Quick Start](./KEYSTORE_QUICKSTART.md)
- [Android Signing Configuration](./ANDROID_SIGNING.md)

---

**Created:** December 2024
**Status:** Active configuration guide
