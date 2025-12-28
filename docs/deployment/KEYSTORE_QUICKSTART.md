# Android Keystore Quick Start Guide

## TL;DR - Quick Setup (5 minutes)

### Step 1: Generate Keystore (if you don't have one)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Save these securely:**
- Keystore password: `____________`
- Key password: `____________`
- Key alias: `upload`

### Step 2: Local Setup

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/yourname/upload-keystore.jks
```

### Step 3: Test Local Build

```bash
flutter clean
flutter build apk --release

# Verify signing (should NOT show "Android Debug")
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

### Step 4: GitHub Actions Setup

**4.1: Encode keystore:**
```bash
base64 ~/upload-keystore.jks | tr -d '\n' > keystore.txt
```

**4.2: Add GitHub Secrets:**

Go to: **GitHub repo → Settings → Secrets → Actions → New secret**

Add these 4 secrets:

| Secret Name | Value |
|-------------|-------|
| `KEYSTORE_BASE64` | Paste contents of `keystore.txt` |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_PASSWORD` | Your key password |
| `KEY_ALIAS` | `upload` |

**4.3: Test release:**
```bash
git tag v1.0.0-test
git push origin v1.0.0-test
```

Watch GitHub Actions build and download the signed APK!

## Checklist

- [ ] Keystore generated or obtained
- [ ] Passwords saved in password manager
- [ ] `android/key.properties` created locally
- [ ] Local build tested and verified
- [ ] Keystore encoded to base64
- [ ] All 4 GitHub secrets added
- [ ] Test release created and verified
- [ ] Keystore backed up to 2+ secure locations

## Troubleshooting

### Local build fails with "keystore not found"
→ Check `storeFile` path in `android/key.properties`

### CI build uses debug signing
→ Check all 4 GitHub secrets are set correctly

### "Password incorrect" error
→ Verify passwords in `key.properties` or GitHub secrets

## Important Notes

1. **Never commit** `key.properties` or `*.jks` files to git (they're in `.gitignore`)
2. **Backup keystore** to multiple secure locations (losing it means you can't update your app!)
3. **Test signing** before releasing to users
4. See `ANDROID_SIGNING.md` for complete documentation

---

**Need help?** See detailed guide: [ANDROID_SIGNING.md](./ANDROID_SIGNING.md)
