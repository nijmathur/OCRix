# Google Drive API Scopes

## Current Scopes Used in App

The app uses the following scopes:
```
https://www.googleapis.com/auth/drive.file
https://www.googleapis.com/auth/drive.appdata
```

**drive.file** scope allows:
- Access to files created by the app
- Read/write access to files the app creates

**drive.appdata** scope allows:
- Access to the app's `appDataFolder` (where database backups are stored)
- Required for storing backups in the app-specific folder

## Manual Scope Configuration

### For OAuth Consent Screen:

1. **Go to Google Cloud Console:**
   - Navigate to: https://console.cloud.google.com/
   - Select your project (project ID: 340615948692)

2. **OAuth Consent Screen:**
   - Go to **APIs & Services** > **OAuth consent screen**
   - Scroll to **"Scopes"** section
   - Click **"ADD OR REMOVE SCOPES"**

3. **Add the Drive Scopes:**
   - Search for: `https://www.googleapis.com/auth/drive.file`
   - Check the box next to it
   - Search for: `https://www.googleapis.com/auth/drive.appdata`
   - Check the box next to it
   - Click **"UPDATE"**

4. **Save and Continue:**
   - Click **"SAVE AND CONTINUE"** through the remaining steps

### Alternative Scopes (if needed):

If you need broader access, you can use:

**Read-only access:**
```
https://www.googleapis.com/auth/drive.readonly
```

**Full access (not recommended for security):**
```
https://www.googleapis.com/auth/drive
```

**App Data Folder only (most restrictive):**
```
https://www.googleapis.com/auth/drive.appdata
```

## Recommended Scopes for This App

**Use both:**
- `https://www.googleapis.com/auth/drive.file` - For general file access
- `https://www.googleapis.com/auth/drive.appdata` - For appDataFolder access (required for backups)

These are the scopes currently configured in the app code and provide:
- ✅ Access to appDataFolder (where backups are stored)
- ✅ Access only to files created by the app (most secure)
- ✅ Read and write permissions for app-created files

## Verification

After adding the scope:
1. Wait 2-5 minutes for propagation
2. Users may need to re-authenticate (sign out and sign back in)
3. The app will request the new scope on next sign-in

