# Bug Fix Summary

## Overview

This document summarizes the two critical bugs that were fixed in this branch.

## Bug #1: Scroll Not Working in Documents Tab

### Problem
When searching documents in the Documents tab, users could not scroll through the results. The grid view was completely non-scrollable.

### Root Cause
The `DocumentGrid` widget in `lib/ui/widgets/document_grid.dart` had:
```dart
physics: const NeverScrollableScrollPhysics(),
```

This completely disabled scrolling. The widget was designed to be embedded in parent scrollable widgets (like `SingleChildScrollView` in the Home tab), but was used directly as the body in the Documents tab.

### Solution
Made `DocumentGrid` configurable:
- Added optional `controller`, `physics`, and `shrinkWrap` parameters
- Default physics: `AlwaysScrollableScrollPhysics()` (scrollable)
- Maintained backward compatibility by explicitly setting `NeverScrollableScrollPhysics()` with `shrinkWrap: true` in HomeScreen

### Files Changed
- `lib/ui/widgets/document_grid.dart` - Added configurable parameters
- `lib/ui/screens/home_screen.dart` - Updated to maintain existing behavior

---

## Bug #2: Database Import Fails After App Upgrade

### Problem
When users:
1. Export database from app version A
2. Uninstall and install app version B (or fresh install on new device)
3. Try to import the exported database

The import fails with decryption errors.

### Root Cause

**Encryption uses two components:**
1. **Encryption Key**: Stored in secure storage and persists across app versions
2. **IV (Initialization Vector)**: Was generated randomly on each app initialization but **never stored**

**The issue:**
```dart
// In EncryptionService._loadOrCreateKey()
_key = Key.fromBase64(keyString);  // ✅ Loaded from secure storage
_iv = IV.fromSecureRandom(16);     // ❌ New random IV every time!
```

**Timeline:**
1. **Export**: Database encrypted with IV_A
2. **App Reinstall**: Generates new IV_B
3. **Import**: Tries to decrypt with IV_B, but file was encrypted with IV_A → **FAILURE**

### Solution

**Prepend IV to encrypted data** (cryptographically standard approach):

#### Before (Broken)
```
Encrypted File: [Encrypted Data only]
Decryption: Use random IV from current session → FAILS if IV changed
```

#### After (Fixed)
```
Encrypted File: [IV (16 bytes)][Encrypted Data]
Decryption: Extract IV from first 16 bytes → Always works with correct key
```

#### Implementation Details

**encryptBytes():**
```dart
// Generate unique IV for this operation
final uniqueIV = IV.fromSecureRandom(16);
final encrypted = encrypter.encryptBytes(data, iv: uniqueIV);

// Prepend IV to encrypted data
final result = Uint8List(16 + encrypted.bytes.length);
result.setRange(0, 16, uniqueIV.bytes);  // First 16 bytes = IV
result.setRange(16, result.length, encrypted.bytes);  // Rest = encrypted data
```

**decryptBytes():**
```dart
// Extract IV from first 16 bytes
final ivBytes = encryptedBytes.sublist(0, 16);
final extractedIV = IV(ivBytes);

// Extract encrypted data (everything after first 16 bytes)
final encryptedData = encryptedBytes.sublist(16);

// Decrypt using extracted IV
final decrypted = encrypter.decryptBytes(Encrypted(encryptedData), iv: extractedIV);
```

### Benefits
1. ✅ **Portable**: Encrypted files work across app versions and devices
2. ✅ **Secure**: Each file uses unique IV (more secure than shared IV)
3. ✅ **Self-contained**: IV stored with data, not separately
4. ✅ **Standard**: Follows cryptographic best practices

### Files Changed
- `lib/services/encryption_service.dart`
  - Updated `encryptBytes()` / `decryptBytes()`
  - Updated `encryptText()` / `decryptText()`
  - Removed `_iv` field
  - Added documentation

---

## Backward Compatibility Notes

### ⚠️ BREAKING CHANGE

**Old encrypted data cannot be decrypted with the new code** because:
- Old format: `[Encrypted Data only]` (expected global IV)
- New format: `[IV][Encrypted Data]` (self-contained)

### Migration Options

#### Option 1: Force Re-encryption (Recommended for Beta/Testing)
1. Before deploying this fix, export all databases
2. Deploy new version
3. Users manually re-scan documents or re-import

#### Option 2: Gradual Migration (Recommended for Production)
Add backward compatibility code in `decryptBytes()`:

```dart
Future<List<int>> decryptBytes(List<int> encryptedBytes) async {
  // Try new format first (has prepended IV)
  if (encryptedBytes.length >= 16) {
    try {
      // Extract IV and decrypt
      final ivBytes = encryptedBytes.sublist(0, 16);
      final extractedIV = IV(ivBytes);
      final encryptedData = encryptedBytes.sublist(16);
      final decrypted = encrypter.decryptBytes(Encrypted(encryptedData), iv: extractedIV);
      return decrypted.toList();
    } catch (e) {
      // If new format fails, try old format
      logWarning('New format decryption failed, trying legacy format');
    }
  }

  // Fallback to old format (use stored/generated IV)
  // Load legacy IV from secure storage if exists
  final legacyIV = await _loadLegacyIV();
  final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
  final decrypted = encrypter.decryptBytes(encrypted, iv: legacyIV);

  // Re-encrypt with new format and save
  final reencrypted = await encryptBytes(decrypted);
  // ... save reencrypted data ...

  return decrypted.toList();
}
```

#### Option 3: Version Marker
Prepend a version byte to identify format:
```
Version 1: [0x01][Encrypted Data only]  // Legacy
Version 2: [0x02][IV][Encrypted Data]   // New format
```

### Recommendation

For current state (pre-production):
- **Option 1**: Accept breaking change, require fresh exports
- Add migration warning in app:
  ```
  "Database import format changed. Please export your database
   again from the app before upgrading."
  ```

For production apps with users:
- **Option 2**: Implement backward compatibility
- Gradually migrate old encrypted data to new format
- Remove legacy support after migration period (e.g., 3 months)

---

## Testing Checklist

### Scroll Fix
- [ ] Open Documents tab
- [ ] Search for documents
- [ ] Verify grid view scrolls smoothly
- [ ] Switch to list view, verify scrolling works
- [ ] Verify Home tab recent documents still works (non-scrollable in parent ScrollView)

### Database Import Fix
- [ ] Export database to Google Drive
- [ ] Uninstall app completely
- [ ] Install fresh version
- [ ] Sign in with Google
- [ ] Import database from Google Drive
- [ ] Verify all documents are intact
- [ ] Verify encrypted data is readable

### Cross-Device Testing
- [ ] Export database from Device A
- [ ] Import database on Device B
- [ ] Verify all data is accessible

---

## Deployment Notes

1. **Update release notes** to mention the encryption format change
2. **Add migration warning** if supporting backward compatibility
3. **Test on clean install** before releasing
4. **Document** the IV-prepending approach in architecture docs
5. **Consider** adding database backup reminder before upgrade

---

## Additional Context

### Why IV Matters

The IV (Initialization Vector) is critical for AES encryption:
- Without IV: Same plaintext → same ciphertext (pattern leakage)
- With unique IV: Same plaintext → different ciphertext (secure)

**Best practice:** Generate unique IV per encryption operation and store it with encrypted data.

### Industry Standard Approach

Our fix follows industry standards:
- OpenSSL: Prepends IV to encrypted data
- Most encryption libraries: Store IV with ciphertext
- NIST guidelines: IV should be unpredictable and unique per operation

---

**Branch:** `bugfix/scroll-and-db-import-fixes`
**Created:** 2025-12-14
**Status:** Ready for review and testing
