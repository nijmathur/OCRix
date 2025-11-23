# Enable Google Drive API

## Error
The Google Drive API is not enabled in your Google Cloud Console project.

## Quick Fix

1. **Go to Google Cloud Console:**
   - Visit: https://console.developers.google.com/apis/api/drive.googleapis.com/overview?project=340615948692
   - Or manually:
     - Go to https://console.cloud.google.com/
     - Select your project (project ID: 340615948692)
     - Navigate to **APIs & Services** > **Library**
     - Search for "Google Drive API"
     - Click on it

2. **Enable the API:**
   - Click the **"Enable"** button
   - Wait for it to enable (usually takes a few seconds)

3. **Wait for Propagation:**
   - After enabling, wait 2-5 minutes for the change to propagate to Google's servers

4. **Try Export Again:**
   - Go back to the app
   - Try exporting the database again

## Alternative: Direct Link
Click this link to go directly to the API page:
https://console.developers.google.com/apis/api/drive.googleapis.com/overview?project=340615948692

Then click **"Enable"** button.

## Note
You need both APIs enabled:
- ✅ Google Sign-In API (already enabled - that's why sign-in works)
- ❌ Google Drive API (needs to be enabled - that's why export fails)

