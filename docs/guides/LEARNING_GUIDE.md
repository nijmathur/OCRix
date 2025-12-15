# OCRix - Learning Guide for Dart/Flutter Beginners

Welcome! This guide will help you master the OCRix codebase. Since you know programming but are new to Dart/Flutter and mobile development, we'll build your understanding from the ground up.

## 📚 Table of Contents

1. [What is This Project?](#what-is-this-project)
2. [Dart Language Basics](#dart-language-basics)
3. [Flutter Framework Basics](#flutter-framework-basics)
4. [Project Structure](#project-structure)
5. [Key Concepts in This Codebase](#key-concepts-in-this-codebase)
6. [Code Flow Walkthrough](#code-flow-walkthrough)
7. [How to Explore the Code](#how-to-explore-the-code)
8. [Common Patterns You'll See](#common-patterns-youll-see)

---

## What is This Project?

**OCRix** is a privacy-first document scanner app that:
- Takes photos of documents using the camera
- Extracts text from images using OCR (Optical Character Recognition)
- Stores documents locally in an encrypted database
- Allows full-text search through your documents
- Can sync with cloud storage (Google Drive, etc.)

It's built with **Flutter** (Google's cross-platform UI framework) using **Dart** as the programming language.

---

## Dart Language Basics

If you know JavaScript, Python, or Java, Dart will feel familiar. Here are the key differences and features:

### 1. **Variables and Types**

```dart
// Explicit type
String name = "John";
int age = 30;
bool isActive = true;

// Type inference (Dart figures out the type)
var email = "john@example.com";  // Dart knows it's a String
final pi = 3.14;  // Final = can't be reassigned (like const in JS)
const appName = "OCRix";  // Compile-time constant

// Nullable types (big in Dart!)
String? nullableString;  // Can be null
String nonNullableString = "required";  // Cannot be null
```

### 2. **Functions**

```dart
// Regular function
String greet(String name) {
  return "Hello, $name";
}

// Arrow function (single expression)
String greet(String name) => "Hello, $name";

// Optional parameters
void printInfo(String name, {int? age, String? city}) {
  print("Name: $name");
  if (age != null) print("Age: $age");
}

// Positional optional parameters
void printInfo(String name, [int? age, String? city]) { }
```

### 3. **Classes and Objects**

```dart
class Document {
  // Properties
  final String id;
  final String title;
  final DateTime createdAt;
  
  // Constructor
  Document({
    required this.id,
    required this.title,
    required this.createdAt,
  });
  
  // Named constructor
  Document.create({required String title}) 
    : this(
        id: Uuid().v4(),
        title: title,
        createdAt: DateTime.now(),
      );
  
  // Method
  String getSummary() {
    return "$title - Created: $createdAt";
  }
}

// Usage
final doc = Document.create(title: "My Document");
```

### 4. **Async/Await (Like JavaScript/Python)**

```dart
// Async function
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 1));
  return "Data loaded";
}

// Error handling
Future<void> loadDocument() async {
  try {
    final data = await fetchData();
    print(data);
  } catch (e) {
    print("Error: $e");
  }
}
```

### 5. **Collections**

```dart
// Lists (like arrays)
List<String> names = ["Alice", "Bob", "Charlie"];
names.add("David");

// Maps (like objects/dictionaries)
Map<String, int> ages = {
  "Alice": 25,
  "Bob": 30,
};

// Sets (unique values)
Set<String> uniqueNames = {"Alice", "Bob", "Alice"};  // {"Alice", "Bob"}
```

### 6. **Null Safety (Important!)**

Dart is null-safe by default:

```dart
String? nullable;  // Can be null
String nonNullable = "value";  // Cannot be null

// Null checking
if (nullable != null) {
  print(nullable.length);  // Safe to use
}

// Null-aware operators
String result = nullable ?? "default";  // Use "default" if nullable is null
String? first = names?.first;  // Returns null if names is null
```

---

## Flutter Framework Basics

Flutter is a UI framework where **everything is a widget**.

### 1. **Widgets = UI Components**

Think of widgets like React components or HTML elements:

```dart
// Stateless widget (no internal state)
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => print("Clicked"),
      child: Text("Click Me"),
    );
  }
}

// Stateful widget (has internal state)
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Count: $count"),
        ElevatedButton(
          onPressed: () {
            setState(() {
              count++;  // Triggers UI rebuild
            });
          },
          child: Text("Increment"),
        ),
      ],
    );
  }
}
```

### 2. **Common Widgets**

```dart
// Layout widgets
Container()          // Box with padding, margin, decoration
Column()             // Vertical layout (like flexbox column)
Row()                // Horizontal layout (like flexbox row)
Stack()              // Overlay widgets on top of each other
Padding()            // Adds padding
SizedBox()           // Fixed-size box

// Content widgets
Text("Hello")        // Text display
Image()              // Image display
Icon(Icons.star)     // Icon
Button()             // Buttons (ElevatedButton, TextButton, etc.)
TextField()          // Text input

// Material Design widgets (pre-built UI components)
AppBar()             // Top app bar
Card()               // Material card
Scaffold()           // Basic page structure
```

### 3. **Widget Tree**

Flutter builds UIs as a tree:

```
MaterialApp
  └── Scaffold
      ├── AppBar
      │   └── Text("Title")
      └── Body
          └── Column
              ├── Text("Hello")
              └── Button
```

### 4. **BuildContext**

`BuildContext` is like a "location" in the widget tree - used for:
- Getting theme data
- Navigation
- Finding parent widgets

```dart
Widget build(BuildContext context) {
  final theme = Theme.of(context);  // Get theme
  Navigator.push(context, ...);      // Navigate
  return Container();
}
```

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models (like TypeScript interfaces)
│   ├── document.dart           # Document data structure
│   ├── user_settings.dart      # User settings data
│   └── audit_log.dart          # Audit log entries
├── services/                    # Business logic (like backend services)
│   ├── database_service.dart   # SQLite database operations
│   ├── ocr_service.dart        # Text extraction from images
│   ├── camera_service.dart     # Camera operations
│   ├── encryption_service.dart # Encryption/decryption
│   └── storage_provider_service.dart # Cloud storage (Google Drive, etc.)
├── providers/                   # State management (Riverpod)
│   ├── document_provider.dart  # Document state management
│   └── settings_provider.dart  # Settings state management
├── ui/
│   ├── screens/                # Full-page UI screens
│   │   ├── home_screen.dart
│   │   ├── scanner_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/                # Reusable UI components
│       ├── document_card.dart
│       └── document_grid.dart
└── utils/                       # Helper functions
    ├── constants.dart          # App-wide constants
    └── helpers.dart            # Utility functions
```

**Think of it like this:**
- **Models** = Data structures (what data looks like)
- **Services** = Business logic (what the app does)
- **Providers** = State management (where data lives)
- **UI** = User interface (what users see)

---

## Key Concepts in This Codebase

### 1. **Riverpod - State Management**

Riverpod is like Redux or MobX - it manages app state.

**Providers** = Where state lives
**Notifiers** = How state changes

```dart
// Define a provider (like a Redux store)
final documentListProvider = FutureProvider<List<Document>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getAllDocuments();
});

// Use in UI
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);
    
    return documentsAsync.when(
      data: (documents) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text("Error: $error"),
    );
  }
}
```

**Key Riverpod concepts:**
- `Provider` = Simple value provider (like a service singleton)
- `FutureProvider` = Async data that loads once
- `StateNotifierProvider` = State that can be modified
- `ref.watch()` = Listen to changes (rebuilds widget when state changes)
- `ref.read()` = Read once (doesn't rebuild)

### 2. **AsyncValue - Handling Async Data**

`AsyncValue<T>` is Riverpod's way of handling async data:

```dart
AsyncValue<List<Document>> documentsAsync;

// Pattern you'll see everywhere:
documentsAsync.when(
  data: (documents) => /* Show data */,
  loading: () => /* Show loading spinner */,
  error: (error, stack) => /* Show error */,
);
```

### 3. **Singleton Pattern**

Services use singletons (one instance shared app-wide):

```dart
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;  // Always returns same instance
  DatabaseService._internal();  // Private constructor
}
```

### 4. **Dependency Injection with Riverpod**

Instead of creating services directly, we use providers:

```dart
// Define service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Use it
class DocumentNotifier extends StateNotifier<...> {
  final DatabaseService _databaseService;
  
  DocumentNotifier(this._databaseService) : super(...);
  
  Future<void> loadDocuments() async {
    final docs = await _databaseService.getAllDocuments();
    // ...
  }
}

// Wire it up
final documentNotifierProvider = StateNotifierProvider<...>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return DocumentNotifier(dbService);
});
```

### 5. **JSON Serialization**

Models use code generation for JSON:

```dart
@JsonSerializable()
class Document {
  final String id;
  // ...
  
  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);  // Generated code
  Map<String, dynamic> toJson() => _$DocumentToJson(this);  // Generated
}
```

Run `dart run build_runner build` to generate `*.g.dart` files.

---

## Code Flow Walkthrough

Let's trace what happens when a user scans a document:

### Step 1: User Taps "Scan" Button

```dart
// In home_screen.dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScannerScreen()),
    );
  },
)
```

### Step 2: Scanner Screen Initializes

```dart
// In scanner_screen.dart
class ScannerScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize camera when screen loads
    ref.read(scannerNotifierProvider.notifier).initializeCamera();
  }
}
```

### Step 3: Camera Service Initializes

```dart
// In camera_service.dart
Future<void> initialize() async {
  final cameras = await availableCameras();
  _controller = CameraController(
    cameras[0],
    ResolutionPreset.high,
  );
  await _controller.initialize();
}

// In providers/document_provider.dart
class ScannerNotifier extends StateNotifier<ScannerState> {
  Future<void> initializeCamera() async {
    await _cameraService.initialize();
    // Update state
    state = state.copyWith(isInitialized: true);
  }
}
```

### Step 4: User Captures Image

```dart
// User taps capture button
onPressed: () async {
  final imagePath = await ref
      .read(scannerNotifierProvider.notifier)
      .captureImage();
}

// In scanner_notifier
Future<String?> captureImage() async {
  final imagePath = await _cameraService.captureImage();
  state = state.copyWith(lastCapturedImage: imagePath);
  return imagePath;
}
```

### Step 5: OCR Extracts Text

```dart
// In document_provider.dart
Future<String> scanDocument({required String imagePath, ...}) async {
  // Extract text using OCR
  final ocrResult = await _ocrService.extractTextFromImage(imagePath);
  
  // ocrResult.text = extracted text
  // ocrResult.confidence = how confident OCR is
}
```

### Step 6: Create Document Object

```dart
final document = Document.create(
  title: title ?? _generateTitle(ocrResult.text, documentType),
  imageData: processedImageData,  // Image stored as bytes
  extractedText: ocrResult.text,
  type: documentType,  // Receipt, contract, etc.
  confidenceScore: ocrResult.confidence,
  // ... more fields
);
```

### Step 7: Save to Database

```dart
// Save to SQLite database
final documentId = await _databaseService.insertDocument(document);

// Database service converts Document to database row
await db.insert('documents', documentToMap(document));
```

### Step 8: Update UI

```dart
// Reload documents list
await _loadDocuments();

// State changes, UI automatically rebuilds
state = AsyncValue.data(documents);
```

---

## How to Explore the Code

### 1. **Start with main.dart**

This is the entry point. See how the app initializes:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OCRixApp()));
}
```

- `ProviderScope` = Wraps app in Riverpod context
- `OCRixApp` = Root widget with MaterialApp (theme, routing)

### 2. **Follow the Data Flow**

Pick a feature (e.g., "viewing documents"):

1. **UI Layer**: Find the screen (`home_screen.dart`)
2. **State Layer**: Find the provider (`document_provider.dart`)
3. **Service Layer**: Find the service (`database_service.dart`)
4. **Data Layer**: See the model (`document.dart`)

### 3. **Understand State Management**

Look for:
- `ConsumerWidget` or `ConsumerStatefulWidget` = Widgets that use Riverpod
- `ref.watch()` = Subscribe to state changes
- `ref.read()` = Read state once
- `StateNotifier` = State that can change
- `AsyncValue` = Loading/error/success states

### 4. **Read Service Files**

Services contain business logic:
- Database operations (CRUD)
- OCR processing
- Camera operations
- Encryption

Each service is usually a singleton.

---

## Common Patterns You'll See

### 1. **Widget Build Pattern**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(...),
    body: Column(
      children: [
        // Widgets here
      ],
    ),
  );
}
```

### 2. **Async Data Handling**

```dart
final dataAsync = ref.watch(someProvider);

return dataAsync.when(
  data: (data) => /* Show data */,
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text("Error"),
);
```

### 3. **Navigation**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NextScreen(),
  ),
);

// Go back
Navigator.pop(context);
```

### 4. **State Updates**

```dart
// In StatefulWidget
setState(() {
  count++;
});

// In StateNotifier
state = state.copyWith(newValue: value);
```

### 5. **Error Handling**

```dart
try {
  final result = await someAsyncOperation();
} catch (e, stackTrace) {
  _logger.e('Error: $e');
  state = AsyncValue.error(e, stackTrace);
}
```

### 6. **CopyWith Pattern**

Immutable objects use `copyWith`:

```dart
final updatedDoc = document.copyWith(
  title: "New Title",
  updatedAt: DateTime.now(),
);
```

---

## Next Steps

1. **Run the app**: `flutter run`
2. **Read one screen at a time**: Start with `home_screen.dart`
3. **Trace one feature**: Pick something simple (like viewing documents)
4. **Modify something small**: Change text, add a button
5. **Read service files**: Understand the business logic
6. **Check the docs folder**: Architecture and API docs

---

## Quick Reference

### Dart vs JavaScript/Python

| Concept | JavaScript | Dart |
|---------|-----------|------|
| Variable | `let x = 5` | `int x = 5` or `var x = 5` |
| Nullable | `let x = null` | `int? x = null` |
| Async | `async/await` | `Future<T>` + `async/await` |
| Class | `class X {}` | `class X {}` (very similar) |
| Arrow | `() => value` | `() => value` (same!) |

### Flutter vs React

| Concept | React | Flutter |
|---------|-------|---------|
| Component | `function Component()` | `class Widget extends StatelessWidget` |
| State | `useState()` | `StatefulWidget` + `setState()` |
| Props | `function X({props})` | `Widget({this.prop})` |
| Build | `return <div>...</div>` | `Widget build() => Widget(...)` |

---

## Common Issues You Might Encounter

### 1. **Null Safety Errors**

```dart
// Error: String? cannot be assigned to String
String name = nullableString;  // ❌

// Fix
String name = nullableString ?? "default";  // ✅
if (nullableString != null) {
  String name = nullableString;  // ✅
}
```

### 2. **Async/Await Issues**

```dart
// Error: Future<String> assigned to String
String data = fetchData();  // ❌

// Fix
String data = await fetchData();  // ✅ (in async function)
```

### 3. **State Not Updating**

```dart
// Error: Direct mutation doesn't rebuild
state.value++;  // ❌

// Fix
state = state.copyWith(value: state.value + 1);  // ✅
// or in StatefulWidget:
setState(() {
  count++;
});
```

---

Happy learning! 🚀 Start with `main.dart` and follow the flow. Don't hesitate to explore and experiment!

