# Audit Logging System

## Overview

The OCRix app implements a comprehensive, tamper-proof audit logging system that tracks all user actions, navigation events, and database operations in a separate, secure audit database.

## Architecture

### Separate Audit Database

-   **Database Name:** `audit_log.db` (separate from main `privacy_documents.db`)
-   **Location:** `/data/data/com.ocrix.app/databases/audit_log.db`
-   **Purpose:** Immutable record of all app activities
-   **Tamper-Proof:** Uses checksums and chain verification

### Logging Levels

The system supports three logging levels with priority-based filtering:

#### 1. COMPULSORY (Priority 3 - Highest)

-   **Always logged** - Cannot be disabled
-   **What's logged:**
    -   All database reads
    -   All database writes (create, update, delete)
    -   Critical system operations
-   **Default:** Only this level is enabled by default

#### 2. INFO (Priority 1 - Medium)

-   **User actions** - All actions performed by users
-   **What's logged:**
    -   Document scanning/creation
    -   Document updates
    -   Document deletions
    -   Search operations
    -   Export/import operations
-   **Requires:** Setting log level to INFO or VERBOSE

#### 3. VERBOSE (Priority 2 - Lowest)

-   **Navigation events** - Screen transitions
-   **What's logged:**
    -   Navigation between screens
    -   Feature access
    -   UI interactions
-   **Requires:** Setting log level to VERBOSE

## Tamper-Proof Mechanisms

### 1. Checksum Verification

-   Each audit entry includes a SHA-256 checksum
-   Checksum is calculated from all entry data (excluding checksum itself)
-   Any modification to entry data will invalidate the checksum

### 2. Chain Verification

-   Each entry links to the previous entry via:
    -   `previousEntryId` - ID of previous entry
    -   `previousChecksum` - Checksum of previous entry
-   Creates an immutable chain of audit entries
-   Any break in the chain indicates tampering

### 3. Read-Only Operations

-   Audit database supports only INSERT operations
-   No UPDATE or DELETE operations allowed
-   Entries are append-only

### 4. Integrity Verification

-   `verifyIntegrity()` method checks:
    -   All entry checksums
    -   Chain integrity
    -   Returns list of compromised entry IDs

## Database Schema

```sql
CREATE TABLE audit_entries (
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,              -- INFO, VERBOSE, or COMPULSORY
  action TEXT NOT NULL,              -- create, read, update, delete, etc.
  resource_type TEXT NOT NULL,       -- document, database, navigation, etc.
  resource_id TEXT NOT NULL,         -- ID of affected resource
  user_id TEXT NOT NULL,             -- User who performed action
  timestamp INTEGER NOT NULL,        -- When action occurred
  details TEXT,                      -- Additional details
  location TEXT,                     -- GPS coordinates if available
  device_info TEXT,                  -- Device information
  is_success INTEGER NOT NULL,      -- Whether action succeeded
  error_message TEXT,                -- Error if failed
  checksum TEXT NOT NULL,            -- SHA-256 checksum
  previous_entry_id TEXT,            -- Chain to previous entry
  previous_checksum TEXT,            -- Previous entry's checksum
  created_at INTEGER NOT NULL
);
```

## Usage

### Basic Logging

```dart
// Get audit logging service
final auditService = ref.read(auditLoggingServiceProvider);

// Log COMPULSORY event (always logged)
await auditService.logCompulsory(
  action: AuditAction.create,
  resourceType: 'document',
  resourceId: documentId,
  details: 'Document created',
);

// Log INFO event (user actions)
await auditService.logInfoAction(
  action: AuditAction.update,
  resourceType: 'document',
  resourceId: documentId,
  details: 'User updated document',
);

// Log VERBOSE event (navigation)
await auditService.logNavigation(
  fromScreen: 'HomeScreen',
  toScreen: 'DocumentDetailScreen',
  details: 'User navigated to document detail',
);
```

### Database Operations (Automatic)

Database operations are automatically logged at COMPULSORY level:

```dart
// Database reads are automatically logged
final document = await databaseService.getDocument(id);

// Database writes are automatically logged
await databaseService.insertDocument(document);
await databaseService.updateDocument(document);
await databaseService.deleteDocument(id);
```

### Navigation (Automatic)

Navigation events are automatically logged at VERBOSE level via `AuditNavigationObserver`:

```dart
// Automatically logs: HomeScreen -> DocumentDetailScreen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DocumentDetailScreen()),
);
```

## Configuration

### Setting Log Level

```dart
final auditService = ref.read(auditLoggingServiceProvider);

// Set to INFO level (logs INFO + COMPULSORY)
auditService.setLogLevel(AuditLogLevel.info);

// Set to VERBOSE level (logs all levels)
auditService.setLogLevel(AuditLogLevel.verbose);

// Set to COMPULSORY only (default)
auditService.setLogLevel(AuditLogLevel.compulsory);
```

### Setting User ID

```dart
auditService.setUserId('user123');
```

## Querying Audit Logs

```dart
// Get all audit entries
final entries = await auditService.getAuditEntries();

// Get entries by level
final compulsoryEntries = await auditService.getAuditEntries(
  level: AuditLogLevel.compulsory,
);

// Get entries by date range
final recentEntries = await auditService.getAuditEntries(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

// Get entry count
final count = await auditService.getEntryCount();
```

## Integrity Verification

```dart
// Verify all entries
final failedEntries = await auditService.verifyIntegrity();

if (failedEntries.isEmpty) {
  print('All audit entries are valid');
} else {
  print('Found ${failedEntries.length} compromised entries');
}
```

## Security Features

1. **Immutable Records:** Once written, entries cannot be modified
2. **Chain Verification:** Each entry verifies the previous entry's integrity
3. **Checksum Protection:** SHA-256 checksums prevent data tampering
4. **Separate Database:** Isolated from main database for security
5. **No Direct Access:** Only through service interface

## Performance Considerations

-   **Async Logging:** All logging is asynchronous and non-blocking
-   **Level Filtering:** Only logs events at or above configured level
-   **Indexed Queries:** Database indexes on timestamp, level, and action
-   **Efficient Storage:** Minimal overhead per entry

## Default Behavior

-   **Default Level:** COMPULSORY only
-   **Automatic Logging:** Database operations and navigation
-   **User Actions:** Logged when level is INFO or higher
-   **Failure Handling:** Audit logging failures don't break app functionality

## Migration

The audit database is created automatically on first run. No migration needed for existing installations.

## Best Practices

1. **Always log COMPULSORY events** for database operations
2. **Log INFO events** for user-initiated actions
3. **Log VERBOSE events** for navigation and UI interactions
4. **Verify integrity** periodically or on app startup
5. **Set user ID** immediately after authentication
6. **Don't log sensitive data** in details field

## Example Audit Entry

```json
{
	"id": "550e8400-e29b-41d4-a716-446655440000",
	"level": "COMPULSORY",
	"action": "create",
	"resourceType": "database",
	"resourceId": "document/abc123",
	"userId": "user123",
	"timestamp": "2024-01-15T10:30:00Z",
	"details": "Document created: Receipt #123",
	"deviceInfo": "android",
	"isSuccess": true,
	"checksum": "a1b2c3d4e5f6...",
	"previousEntryId": "previous-entry-id",
	"previousChecksum": "previous-checksum"
}
```
