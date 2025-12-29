# Android Keystore Security Guide

## Important Security Notice

The Android release keystore (`release-keystore.jks`) is properly configured to be ignored by git and should **NEVER** be committed to version control.

## Current Status

✅ **SECURE**: The keystore file is listed in `.gitignore` (lines 132-134)
✅ **VERIFIED**: No keystore files are tracked in git history
✅ **PROTECTED**: Keystore exists locally but is not committed

## Keystore Location

The release keystore should be stored at:
```
android/app/release-keystore.jks
```

## For New Team Members

If you need to build a release version of the app:

1. **Request the keystore** from your team lead (never via email or insecure channels)
2. **Place it** in `android/app/release-keystore.jks`
3. **Verify it's ignored**:
   ```bash
   git check-ignore android/app/release-keystore.jks
   # Should output: android/app/release-keystore.jks
   ```

## Generating a New Keystore

If you need to generate a new keystore (e.g., for a new app variant):

```bash
keytool -genkey -v -keystore android/app/release-keystore.jks \
  -alias ocrix-release-key \
  -keyalg RSA -keysize 2048 -validity 10000

# Use a strong password (minimum 16 characters with mixed case, numbers, symbols)
```

## Keystore Password Management

**NEVER** hardcode passwords in:
- Source code
- Configuration files
- CI/CD scripts
- Documentation

Store passwords in:
- Team password manager (1Password, LastPass, etc.)
- CI/CD secret management (GitHub Secrets, etc.)
- Local secure storage only

## If Keystore is Compromised

If you suspect the keystore has been compromised:

1. **Immediately notify** the security team
2. **Generate a new keystore** with a different password
3. **Update Google Play Console** with the new keystore (if app is published)
4. **Rotate all credentials** associated with the app
5. **Audit git history** to ensure it was never committed

## Security Checklist

Before releasing:
- [ ] Keystore file is not in git (`git ls-files | grep keystore` should return nothing)
- [ ] Keystore password is stored securely (not in code)
- [ ] Keystore file permissions are restrictive (`chmod 600`)
- [ ] Backup keystore is stored in secure team location
- [ ] All team members know keystore security policy

## References

- [Android App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
