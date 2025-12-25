# Where Are Database Backups Stored?

## Location: appDataFolder

Your database backups are stored in Google Drive's **`appDataFolder`** - a special hidden folder that's app-specific.

## Why appDataFolder?

✅ **Privacy**: Backups are isolated from your regular files  
✅ **Security**: Only accessible by the OCRix app  
✅ **Clean**: Doesn't clutter your regular Google Drive  
✅ **Automatic**: Managed by Google Drive API

## Can I See It in Google Drive?

**No** - `appDataFolder` is **not visible** in:
- Google Drive web interface (drive.google.com)
- Google Drive mobile app
- Google Drive desktop app

This is by design - it's a hidden, app-specific storage area.

## How to Access Your Backups

### Option 1: Use the App (Recommended)
1. Open OCRix app
2. Go to **Settings** → **Backup & Export**
3. Tap **"Import Database"**
4. You'll see a list of all your backups with:
   - File name
   - Creation date
   - File size

### Option 2: View via Google Drive API
The backups are accessible programmatically via the Google Drive API, but not through the regular Drive interface.

## Backup File Details

- **Location**: `appDataFolder/backups/`
- **File Format**: Encrypted (`.db.enc`)
- **Naming**: `ocrix_database_backup_YYYY-MM-DD.db.enc`
- **Encryption**: AES-256 encrypted before upload

## Want to Store in Regular Drive?

If you want backups visible in your regular Google Drive, we can modify the code to store them in a regular Drive folder instead of `appDataFolder`. However, `appDataFolder` is recommended for:
- Better privacy
- Automatic cleanup if app is uninstalled
- Separation from user files

## Verify Backup Exists

To verify your backup was created:
1. Use **"Import Database"** in the app
2. You should see your backup listed there
3. If you see it, the backup is successfully stored in Google Drive

