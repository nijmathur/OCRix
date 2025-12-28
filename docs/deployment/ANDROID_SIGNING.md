# Android App Signing Configuration

## Overview

This document explains how to set up proper release signing for Android APKs and App Bundles. The app uses a keystore-based signing configuration that works both locally and in GitHub Actions CI/CD.

## Current Configuration

### build.gradle Setup

The `android/app/build.gradle` file is configured to:
1. Load signing credentials from `android/key.properties`
2. Use release signing config if keystore is available
3. Fall back to debug signing if keystore is not configured (for PRs and local dev)

**Signing Config:**
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

### Files Required

1. **Keystore file**: `upload-keystore.jks` (stored in `android/app/` during build)
2. **Key properties**: `android/key.properties` (contains passwords and alias)

Both files are `.gitignore`d for security.

## Step 1: Create a Keystore

### Option A: Create New Keystore

Run this command to generate a new keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

**You will be prompted for:**
- Keystore password (store this securely!)
- Key password (can be same as keystore password)
- Name, organization, location details

**Important:** Save all information securely! You'll need:
- Keystore password
- Key password
- Key alias (you entered "upload" above)
- Location of keystore file

### Option B: Use Existing Keystore

If you already have a keystore, note:
- Keystore file path
- Keystore password
- Key alias
- Key password

## Step 2: Local Development Setup

### Create key.properties

Create `android/key.properties` with your signing credentials:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

**Security Note:** This file is in `.gitignore` and should **NEVER** be committed to version control.

### Test Local Build

Build a release APK to verify signing works:

```bash
flutter build apk --release
```

Check signing info:
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

You should see your certificate information (not the debug certificate).

## Step 3: GitHub Actions Setup

### 3.1: Encode Keystore to Base64

Encode your keystore file to base64:

```bash
base64 ~/upload-keystore.jks | tr -d '\n' > keystore.txt
```

Copy the contents of `keystore.txt` - you'll need this for GitHub secrets.

### 3.2: Add GitHub Secrets

Go to your GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

Add these 4 secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `KEYSTORE_BASE64` | Contents of `keystore.txt` | Base64-encoded keystore file |
| `KEYSTORE_PASSWORD` | Your keystore password | Keystore password |
| `KEY_PASSWORD` | Your key password | Key password (may be same as keystore) |
| `KEY_ALIAS` | `upload` (or your alias) | Key alias from keystore |

### 3.3: Verify Workflow Configuration

The `.github/workflows/release.yml` workflow should already be configured to:
1. Decode the base64 keystore
2. Create `key.properties` from secrets
3. Build signed APK and AAB

**Workflow steps:**
```yaml
- name: Decode keystore
  env:
    KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
  run: |
    echo "$KEYSTORE_BASE64" | base64 -d > android/app/upload-keystore.jks

- name: Create key.properties
  env:
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
  run: |
    cat > android/key.properties << EOF
    storePassword=$KEYSTORE_PASSWORD
    keyPassword=$KEY_PASSWORD
    keyAlias=$KEY_ALIAS
    storeFile=upload-keystore.jks
    EOF
```

## Step 4: Testing

### Test Local Build

```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Verify signing
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

**Expected output:**
- Should show your certificate details (CN, O, L, etc.)
- Should NOT show "CN=Android Debug"

### Test GitHub Actions Build

1. Create a new tag to trigger release workflow:
```bash
git tag v1.0.0-test
git push origin v1.0.0-test
```

2. Check GitHub Actions:
   - Go to Actions tab
   - Watch the "Release Build" workflow
   - Verify steps complete successfully:
     - ✅ Decode keystore
     - ✅ Create key.properties
     - ✅ Build Android APK
     - ✅ Build Android App Bundle

3. Download artifacts and verify signing:
```bash
# Download APK from GitHub Actions
keytool -printcert -jarfile OCRix-v1.0.0-test.apk
```

## Troubleshooting

### Error: "keystore.jks (No such file or directory)"

**Cause:** `storeFile` path in `key.properties` is incorrect.

**Solution:** Use absolute path or place keystore in `android/app/` and use relative path:
```properties
storeFile=upload-keystore.jks
```

### Error: "Keystore was tampered with, or password was incorrect"

**Cause:** Wrong keystore password or key password.

**Solution:** Verify passwords are correct. Try:
```bash
keytool -list -v -keystore upload-keystore.jks
```

### Warning: "KEYSTORE_BASE64 secret not set, will use debug signing"

**Cause:** GitHub secret `KEYSTORE_BASE64` not configured.

**Solution:** Add the secret in GitHub repository settings (see Step 3.2).

### Build succeeds but APK uses debug signing

**Cause:** `key.properties` file not found or incorrect.

**Solution:**
1. Check `android/key.properties` exists (locally)
2. Check GitHub secrets are set correctly (CI/CD)
3. Verify `storeFile` path is correct

## Security Best Practices

### Keystore Management

1. **Backup:** Store keystore in multiple secure locations
   - Password manager
   - Encrypted cloud storage
   - Physical secure storage

2. **Never commit:** Keystore and passwords should NEVER be in git
   - Verify `.gitignore` includes:
     ```
     android/key.properties
     *.jks
     *.keystore
     upload-keystore.jks
     ```

3. **Rotate secrets:** If keystore is compromised:
   - Generate new keystore
   - Update GitHub secrets
   - Republish app (note: users will need to uninstall old version)

### Password Security

1. **Strong passwords:** Use 16+ character passwords with mixed characters
2. **Password manager:** Store in a secure password manager
3. **Team access:** Limit who has access to keystore/passwords
4. **Separate passwords:** Use different password for keystore vs key (optional but recommended)

## Google Play Store Setup

### For App Bundle (AAB) Upload

When uploading to Google Play for the first time:

1. Build signed AAB:
```bash
flutter build appbundle --release
```

2. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console

3. Google Play will re-sign with their keys for distribution

### Play App Signing

**Recommended:** Enable Google Play App Signing:
- Google manages the final signing key
- You only need the upload key
- Easier key rotation if compromised

**Setup:**
1. Go to Play Console → Your app → Setup → App integrity
2. Enroll in Play App Signing
3. Upload your upload certificate

## Appendix

### Useful Commands

**List keystore contents:**
```bash
keytool -list -v -keystore upload-keystore.jks
```

**Verify APK signature:**
```bash
keytool -printcert -jarfile app-release.apk
```

**Check APK signing version:**
```bash
apksigner verify --verbose app-release.apk
```

**Export certificate from keystore:**
```bash
keytool -export -rfc -keystore upload-keystore.jks -alias upload -file upload_cert.pem
```

### File Locations

| File | Location | Committed? | Purpose |
|------|----------|-----------|---------|
| `upload-keystore.jks` | `android/app/` (during build) | ❌ No | Keystore file |
| `key.properties` | `android/` | ❌ No | Signing credentials |
| `build.gradle` | `android/app/` | ✅ Yes | Build configuration |
| `proguard-rules.pro` | `android/app/` | ✅ Yes | Code obfuscation rules |

### References

- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Keytool Documentation](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)

---

**Created:** December 2024
**Last Updated:** December 2024
**Status:** ✅ Active configuration
