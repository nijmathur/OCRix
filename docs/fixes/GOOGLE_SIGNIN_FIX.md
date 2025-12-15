# Google Sign-In Error Fix Guide

## Current Configuration

**Package Name:** `com.ocrix.app`

**Current Debug SHA-1 Fingerprint (on this machine):**
```
C6:1F:33:98:71:80:65:3C:0C:0E:66:40:BE:8A:A4:8A:09:87:EE:40
```

**SHA-1 in Google Cloud Console:**
```
E8:00:0D:E5:ED:DE:16:FD:06:95:83:D5:DF:99:BD:1A:08:58:ED:F5
```

**Status:** ❌ Mismatch - The current SHA-1 doesn't match the one in Cloud Console

## Error Code 10: DEVELOPER_ERROR

The error `ApiException: 10` means your app is misconfigured in Google Cloud Console.

## Steps to Fix

### 1. Go to Google Cloud Console
- Navigate to: https://console.cloud.google.com/
- Select your project (or create one if needed)

### 2. Enable Google Sign-In API
- Go to **APIs & Services** > **Library**
- Search for "Google Sign-In API" or "Google+ API"
- Click **Enable**

### 3. Add Current SHA-1 to Existing OAuth Client
- Go to **APIs & Services** > **Credentials**
- Find your existing OAuth 2.0 Client ID for Android (the one with SHA-1 `E8:00:0D:E5:ED:DE:16:FD:06:95:83:D5:DF:99:BD:1A:08:58:ED:F5`)
- Click on it to edit
- Scroll down to **SHA-1 certificate fingerprints**
- Click **+ ADD SHA-1 CERTIFICATE FINGERPRINT**
- Add the current SHA-1: `C6:1F:33:98:71:80:65:3C:0C:0E:66:40:BE:8A:A4:8A:09:87:EE:40`
- Click **Save**

**Note:** You can have multiple SHA-1 fingerprints on the same OAuth client. This allows you to use the same credentials from different machines or with different keystores.

### 4. Verify Configuration
- Make sure the package name matches exactly: `com.ocrix.app`
- Make sure **both** SHA-1 fingerprints are present:
  - `E8:00:0D:E5:ED:DE:16:FD:06:95:83:D5:DF:99:BD:1A:08:58:ED:F5` (existing)
  - `C6:1F:33:98:71:80:65:3C:0C:0E:66:40:BE:8A:A4:8A:09:87:EE:40` (newly added)
- The SHA-1 should include colons (`:`)

### 5. Wait for Propagation
- Changes can take a few minutes to propagate
- Try signing in again after 2-5 minutes

## Important Notes

- **SHA-1 does NOT change** when you build on different devices
- **SHA-1 only changes** if you:
  - Delete and regenerate the debug keystore (`~/.android/debug.keystore`)
  - Use a different keystore for signing
- For release builds, you'll need to add the **release SHA-1** as well

## Getting SHA-1 Again (if needed)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

## Troubleshooting

1. **Double-check package name:** Must be exactly `com.ocrix.app`
2. **Double-check SHA-1:** Copy-paste the exact value above
3. **Check OAuth consent screen:** Must be configured before creating OAuth client
4. **Wait a few minutes:** Google's servers need time to propagate changes
5. **Uninstall and reinstall app:** Sometimes helps clear cached credentials

