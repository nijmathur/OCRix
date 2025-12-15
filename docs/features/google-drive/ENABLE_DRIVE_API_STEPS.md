# Enable Google Drive API - Step by Step

## Important: API vs Scopes

There are TWO different things:
1. **API Enablement** - Makes the API available to your project (THIS IS WHAT'S MISSING)
2. **Scopes** - Permissions the app requests (you already did this)

## Steps to Enable Google Drive API

### Method 1: Direct Link (Easiest)
1. Click this link: https://console.developers.google.com/apis/api/drive.googleapis.com/overview?project=340615948692
2. Click the big **"ENABLE"** button at the top
3. Wait for it to say "API enabled"

### Method 2: Manual Steps
1. Go to: https://console.cloud.google.com/
2. Make sure project **340615948692** is selected (check top bar)
3. Go to **APIs & Services** > **Library**
4. Search for: **"Google Drive API"**
5. Click on **"Google Drive API"** (not "Google Drive File API")
6. Click the **"ENABLE"** button
7. Wait for confirmation

## Verify It's Enabled

1. Go to **APIs & Services** > **Enabled APIs**
2. You should see:
   - ✅ Google Sign-In API
   - ✅ Google Drive API (should be listed here)

## After Enabling

1. **Wait 2-5 minutes** for propagation
2. **Sign out and sign back in** to the app (to refresh tokens)
3. Try exporting again

## Common Mistake

❌ Adding scopes in OAuth consent screen ≠ Enabling the API
✅ You need to ENABLE the API itself in the API Library

