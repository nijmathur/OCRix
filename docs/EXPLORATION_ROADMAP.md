# OCRix - Exploration Roadmap

This roadmap guides you through exploring the codebase step-by-step. Follow this order to build understanding progressively.

## 🎯 Phase 1: Understanding the Basics (30 mins)

### Step 1: App Entry Point
**File**: `lib/main.dart`

**What to look for:**
- How the app starts (`main()` function)
- `ProviderScope` - wraps entire app for state management
- `AppInitializer` - initializes all services before showing UI
- Theme configuration (light/dark mode)

**Questions to answer:**
- What services are initialized before the app starts?
- What happens if initialization fails?

**Try this:**
- Change the app title from "OCRix" to something else
- Modify a color in the theme

---

### Step 2: Data Models
**File**: `lib/models/document.dart`

**What to look for:**
- `Document` class - the core data structure
- All properties a document has (id, title, imageData, extractedText, etc.)
- `Document.create()` - factory constructor (a pattern you'll see often)
- `copyWith()` - immutable updates
- `DocumentType` enum - types of documents (receipt, contract, etc.)
- `@JsonSerializable()` - code generation for JSON

**Questions to answer:**
- What information does each document store?
- How are images stored? (Hint: `Uint8List? imageData`)
- What's the difference between `id`, `cloudId`, and `storageProvider`?

**Try this:**
- Add a new `DocumentType` value (like `insurance`)
- Find where `DocumentType.displayName` is used in the UI

---

### Step 3: Database Service
**File**: `lib/services/database_service.dart`

**What to look for:**
- Singleton pattern (only one instance)
- Database initialization (`_initDatabase()`)
- CRUD operations (`insertDocument`, `getDocument`, `updateDocument`, `deleteDocument`)
- SQL table structure (lines 72-99)
- Encryption setup (`_initializeEncryption()`)
- FTS5 full-text search

**Questions to answer:**
- How is the database encrypted?
- Where is the database file stored?
- How does full-text search work?

**Key methods to understand:**
```dart
Future<String> insertDocument(Document document)
Future<Document?> getDocument(String id)
Future<List<Document>> getAllDocuments({DocumentType? type})
Future<List<Document>> searchDocuments(String query)
```

---

## 🎯 Phase 2: Understanding State Management (45 mins)

### Step 4: Providers Overview
**File**: `lib/providers/document_provider.dart`

**What to look for:**
- `Provider` - simple service providers (like dependency injection)
- `FutureProvider` - async data that loads once
- `StateNotifierProvider` - state that can change
- `DocumentNotifier` - manages document list state
- `ScannerNotifier` - manages camera/scanning state

**Pattern you'll see:**
```dart
// Define provider
final documentNotifierProvider = StateNotifierProvider<...>((ref) {
  final dbService = ref.read(databaseServiceProvider);  // Get dependency
  return DocumentNotifier(dbService);  // Create notifier
});

// Use in UI
final state = ref.watch(documentNotifierProvider);  // Listen to changes
```

**Questions to answer:**
- What's the difference between `ref.watch()` and `ref.read()`?
- How does `AsyncValue` handle loading/error/success states?

**Try this:**
- Find where `documentNotifierProvider` is used in UI files
- Trace how `scanDocument()` updates the state

---

### Step 5: State Flow Example
**Task**: Trace how documents are loaded and displayed

1. **UI Layer** (`lib/ui/screens/home_screen.dart`)
   - Line 36: `ref.watch(documentNotifierProvider)` - watches state
   - Line 105-126: `_buildHomeTab()` - displays documents

2. **State Layer** (`lib/providers/document_provider.dart`)
   - Line 55-66: `DocumentNotifier` constructor - calls `_loadDocuments()`
   - Line 69-78: `_loadDocuments()` - fetches from database

3. **Service Layer** (`lib/services/database_service.dart`)
   - Line 330+: `getAllDocuments()` - queries SQLite

**Flow:**
```
UI watches provider 
  → Notifier loads data 
    → Service queries database 
      → Data flows back 
        → UI rebuilds
```

---

## 🎯 Phase 3: Understanding Features (60 mins)

### Step 6: Camera & Scanning Flow
**Files**: 
- `lib/ui/screens/scanner_screen.dart`
- `lib/services/camera_service.dart`
- `lib/services/ocr_service.dart`

**What to look for:**

1. **Scanner Screen** (`scanner_screen.dart`)
   - TabController for switching between Camera and Details tabs
   - Line 32: Initializes camera when screen loads
   - `_captureImage()` - captures photo
   - `_saveDocument()` - saves document to database

2. **Camera Service** (`camera_service.dart`)
   - `initialize()` - sets up camera controller
   - `captureImage()` - takes photo, saves to temp file

3. **OCR Service** (`ocr_service.dart`)
   - `extractTextFromImage()` - uses Google ML Kit to extract text
   - `categorizeDocument()` - determines document type from text

**Flow:**
```
User opens Scanner Screen
  → Camera initializes
    → User captures image
      → OCR extracts text
        → Document created
          → Saved to database
            → UI updates
```

**Questions to answer:**
- What happens if camera permissions are denied?
- How does OCR categorize documents?
- Where are captured images temporarily stored?

---

### Step 7: Document List & Search
**Files**:
- `lib/ui/screens/document_list_screen.dart`
- `lib/ui/screens/document_detail_screen.dart`

**What to look for:**
- How documents are displayed in a grid/list
- Search functionality (FTS5 full-text search)
- Filtering by document type
- Navigation to document details

**Questions to answer:**
- How does search work? (Check `database_service.dart` for FTS5 queries)
- How are images displayed from `Uint8List`?

---

### Step 8: Settings & Storage Providers
**Files**:
- `lib/ui/screens/settings_screen.dart`
- `lib/services/storage_provider_service.dart`
- `lib/providers/settings_provider.dart`

**What to look for:**
- User settings (encryption, biometric auth, storage provider)
- Google Drive integration
- How storage providers work

---

## 🎯 Phase 4: Advanced Concepts (30 mins)

### Step 9: Encryption Service
**File**: `lib/services/encryption_service.dart`

**What to look for:**
- AES-256 encryption
- Secure key storage using `flutter_secure_storage`
- Biometric authentication
- How encrypted data is stored

**Questions to answer:**
- Where is the encryption key stored?
- How is data encrypted before saving to database?

---

### Step 10: Error Handling
**Task**: Find error handling patterns

**Look for:**
- `try-catch` blocks in services
- `AsyncValue.error()` in providers
- Error UI in widgets (`documentsAsync.when(error: ...)`)

**Pattern:**
```dart
try {
  final result = await operation();
  state = AsyncValue.data(result);
} catch (e, stackTrace) {
  _logger.e('Error: $e');
  state = AsyncValue.error(e, stackTrace);
}
```

---

## 🎯 Phase 5: Practice Exercises

### Exercise 1: Add a New Feature
Add a "favorite" toggle to documents:

1. Add `isFavorite` boolean to `Document` model
2. Add column to database schema
3. Add method to toggle favorite in `DocumentNotifier`
4. Add favorite icon to `DocumentCard` widget
5. Add filter to show only favorites

### Exercise 2: Understand Image Storage
Currently images are stored as BLOB in database. Understand:
- How `Uint8List` works
- How images are converted to/from bytes
- Why images are resized before storage (check `_processImageForStorage`)

### Exercise 3: Trace a Complete Flow
Pick any user action (e.g., "delete document") and trace:
1. UI event (button tap)
2. Provider method called
3. Service method called
4. Database operation
5. State update
6. UI rebuild

---

## 🔍 Useful Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Generate code (for JSON serialization)
dart run build_runner build

# Watch for changes and auto-generate
dart run build_runner watch

# Check for linter errors
flutter analyze

# Format code
dart format lib/
```

---

## 📚 Reading Order for Deep Dive

1. **Start Here** (Foundation):
   - `lib/main.dart` - Entry point
   - `lib/models/document.dart` - Data structure
   - `lib/utils/constants.dart` - Constants

2. **Then Services** (Business Logic):
   - `lib/services/database_service.dart` - Data persistence
   - `lib/services/ocr_service.dart` - Text extraction
   - `lib/services/camera_service.dart` - Camera operations
   - `lib/services/encryption_service.dart` - Security

3. **Then State Management** (How data flows):
   - `lib/providers/document_provider.dart` - Document state
   - `lib/providers/settings_provider.dart` - Settings state

4. **Finally UI** (What users see):
   - `lib/ui/screens/home_screen.dart` - Main screen
   - `lib/ui/screens/scanner_screen.dart` - Scanning
   - `lib/ui/screens/document_list_screen.dart` - Document list
   - `lib/ui/widgets/document_card.dart` - Reusable component

---

## 🐛 Common Questions

### Q: Why do I see `.g.dart` files?
A: These are generated files for JSON serialization. Don't edit them directly. Run `dart run build_runner build` to regenerate.

### Q: What's `ConsumerWidget` vs `StatelessWidget`?
A: `ConsumerWidget` is a `StatelessWidget` that can access Riverpod providers via `ref`. Use `ConsumerWidget` when you need state management.

### Q: Why are services singletons?
A: Services like database and OCR need to be initialized once and shared across the app. Singletons ensure only one instance exists.

### Q: What's the difference between `final`, `const`, and `var`?
A: 
- `const` = compile-time constant, cannot change
- `final` = set once, cannot reassign (runtime constant)
- `var` = can reassign, type inferred

### Q: How do I navigate to a new screen?
A: Use `Navigator.push()`:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```

---

## ✅ Checklist

- [ ] Understand how the app starts (`main.dart`)
- [ ] Know what a `Document` contains (`document.dart`)
- [ ] Understand Riverpod providers (`document_provider.dart`)
- [ ] Trace the scanning flow (camera → OCR → save)
- [ ] Understand how state updates trigger UI rebuilds
- [ ] Know how database operations work
- [ ] Understand error handling patterns
- [ ] Can navigate between screens
- [ ] Know how to add a new feature

---

## 🚀 Next Steps

Once you're comfortable:

1. **Read the docs**: Check `docs/` folder for architecture details
2. **Run tests**: `flutter test` to see test examples
3. **Modify code**: Start with small changes (colors, text)
4. **Add features**: Try the exercises above
5. **Debug**: Use Flutter DevTools for debugging

Happy coding! 🎉

