# Add drive.appdata Scope

## The Error
```
The granted scopes do not allow use of the Application Data folder.
```

## The Problem
The app needs **TWO** scopes to work:
1. ✅ `drive.file` - You already added this
2. ❌ `drive.appdata` - **You need to add this now**

## Quick Fix

1. **Go to OAuth Consent Screen:**
   - Visit: https://console.cloud.google.com/apis/credentials/consent?project=340615948692
   - Or: Google Cloud Console → APIs & Services → OAuth consent screen

2. **Add the AppData Scope:**
   - Scroll to **"Scopes"** section
   - Click **"ADD OR REMOVE SCOPES"**
   - Search for: `https://www.googleapis.com/auth/drive.appdata`
   - Check the box next to it
   - Click **"UPDATE"**

3. **Save and Continue:**
   - Click **"SAVE AND CONTINUE"** through the remaining steps

4. **Sign Out and Sign Back In:**
   - In the app, sign out completely
   - Sign back in (this will request the new scope)
   - Try exporting again

## Both Scopes Needed

Make sure you have BOTH scopes added:
- ✅ `https://www.googleapis.com/auth/drive.file`
- ✅ `https://www.googleapis.com/auth/drive.appdata`

## Why Both?

- **drive.file**: Allows access to files created by the app
- **drive.appdata**: Allows access to the app's `appDataFolder` (where backups are stored)

The app uses `appDataFolder` to store database backups securely, which requires the `drive.appdata` scope.

