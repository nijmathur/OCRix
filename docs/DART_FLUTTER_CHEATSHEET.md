# Dart/Flutter Quick Reference Cheat Sheet

A quick reference for common Dart/Flutter patterns used in this codebase.

## Dart Basics

### Variables

```dart
// Explicit types
String name = "John";
int count = 5;
bool isActive = true;
double price = 9.99;

// Type inference
var email = "john@example.com";  // String
final pi = 3.14;                  // final = can't reassign
const appName = "OCRix";          // const = compile-time constant

// Nullable types (important!)
String? nullableName;             // Can be null
String requiredName = "John";     // Cannot be null

// Lists
List<String> names = ["Alice", "Bob"];
List<int> numbers = [1, 2, 3];
var items = [1, 2, 3];            // Type inferred

// Maps (dictionaries/objects)
Map<String, int> ages = {"Alice": 25, "Bob": 30};
var person = {"name": "John", "age": 30};

// Sets
Set<String> unique = {"a", "b", "a"};  // {"a", "b"}
```

### Functions

```dart
// Regular function
String greet(String name) {
  return "Hello, $name";
}

// Arrow function (single expression)
String greet(String name) => "Hello, $name";

// Named parameters
void printInfo(String name, {int? age, String? city}) {
  print("Name: $name");
  if (age != null) print("Age: $age");
}
printInfo("John", age: 30);

// Positional optional parameters
void printInfo(String name, [int? age, String? city]) { }
printInfo("John", 30);

// Async functions
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 1));
  return "Data";
}
```

### Classes

```dart
class Document {
  // Properties
  final String id;
  final String title;
  
  // Constructor
  Document({required this.id, required this.title});
  
  // Named constructor
  Document.create(String title) 
    : this(id: Uuid().v4(), title: title);
  
  // Method
  String getSummary() => "$title - $id";
  
  // CopyWith pattern (for immutable updates)
  Document copyWith({String? id, String? title}) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }
}
```

### Null Safety

```dart
String? nullable;

// Null check
if (nullable != null) {
  print(nullable.length);  // Safe
}

// Null-aware operators
String result = nullable ?? "default";       // Use default if null
String? first = list?.first;                 // Returns null if list is null
String value = nullable?.toUpperCase() ?? "";  // Chain with default

// Force unwrap (use carefully!)
String value = nullable!;  // Crashes if null
```

### Async/Await

```dart
// Future = like Promise in JavaScript
Future<String> loadData() async {
  await Future.delayed(Duration(seconds: 1));
  return "Done";
}

// Error handling
Future<void> loadData() async {
  try {
    final data = await loadData();
    print(data);
  } catch (e) {
    print("Error: $e");
  }
}

// Multiple futures
Future<void> loadMultiple() async {
  final results = await Future.wait([
    loadData1(),
    loadData2(),
  ]);
}
```

---

## Flutter Basics

### Widgets

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
              count++;  // Triggers rebuild
            });
          },
          child: Text("Increment"),
        ),
      ],
    );
  }
}
```

### Common Widgets

```dart
// Layout
Container(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text("Hello"),
)

Column(
  children: [
    Text("Item 1"),
    Text("Item 2"),
  ],
)

Row(
  children: [
    Icon(Icons.star),
    Text("Rating"),
  ],
)

// Content
Text("Hello World", style: TextStyle(fontSize: 20))
Icon(Icons.star, color: Colors.yellow)
Image.asset("assets/image.png")
Image.network("https://example.com/image.jpg")

// Input
TextField(
  controller: _controller,
  decoration: InputDecoration(labelText: "Name"),
)

// Buttons
ElevatedButton(
  onPressed: () {},
  child: Text("Click"),
)
TextButton(onPressed: () {}, child: Text("Click"))
IconButton(icon: Icon(Icons.add), onPressed: () {})

// Material components
AppBar(title: Text("Title"))
Card(child: Text("Content"))
Scaffold(
  appBar: AppBar(title: Text("App")),
  body: Text("Body"),
)
```

### Riverpod (State Management)

```dart
// Provider (simple value)
final nameProvider = Provider<String>((ref) => "John");

// FutureProvider (async data)
final dataProvider = FutureProvider<List<Item>>((ref) async {
  return await fetchItems();
});

// StateNotifierProvider (state that changes)
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
}

// ConsumerWidget (accesses providers)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(nameProvider);  // Watch = rebuilds on change
    final data = ref.watch(dataProvider);
    
    return Text(name);
  }
}

// ConsumerStatefulWidget
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final name = ref.watch(nameProvider);
    // Use ref.read() for one-time reads
    ref.read(counterProvider.notifier).increment();
    return Text(name);
  }
}

// AsyncValue pattern
final dataAsync = ref.watch(dataProvider);

return dataAsync.when(
  data: (items) => ListView(...),              // Show data
  loading: () => CircularProgressIndicator(),   // Show loading
  error: (error, stack) => Text("Error: $error"),  // Show error
);
```

### Navigation

```dart
// Navigate to new screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NextScreen(),
  ),
);

// Navigate back
Navigator.pop(context);

// Navigate with result
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NextScreen()),
);
// In NextScreen:
Navigator.pop(context, "returned value");

// Named routes (if using routes)
Navigator.pushNamed(context, '/details');
```

### Theming

```dart
// Get theme colors
final theme = Theme.of(context);
final primaryColor = theme.colorScheme.primary;
final textStyle = theme.textTheme.headlineSmall;

// Custom theme
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
  textTheme: TextTheme(...),
  appBarTheme: AppBarTheme(...),
)
```

---

## Common Patterns in This Codebase

### Singleton Pattern

```dart
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;  // Always same instance
  DatabaseService._internal();  // Private constructor
}
```

### CopyWith Pattern (Immutable Updates)

```dart
final updatedDoc = document.copyWith(
  title: "New Title",
  updatedAt: DateTime.now(),
);
```

### Error Handling

```dart
try {
  final result = await operation();
  state = AsyncValue.data(result);
} catch (e, stackTrace) {
  _logger.e('Error: $e');
  state = AsyncValue.error(e, stackTrace);
}
```

### JSON Serialization

```dart
@JsonSerializable()
class Document {
  final String id;
  
  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);  // Generated
  
  Map<String, dynamic> toJson() => _$DocumentToJson(this);  // Generated
}

// Generate with: dart run build_runner build
```

### Enums with Extensions

```dart
enum DocumentType { receipt, contract, invoice }

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.receipt: return "Receipt";
      case DocumentType.contract: return "Contract";
      // ...
    }
  }
}
```

### Factory Constructors

```dart
class Document {
  Document({required this.id, ...});
  
  // Named factory - creates with defaults
  factory Document.create({required String title}) {
    return Document(
      id: Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
      // ... defaults
    );
  }
}
```

---

## Type Comparison Table

| Concept | JavaScript | Dart |
|---------|-----------|------|
| Variable | `let x = 5` | `int x = 5` or `var x = 5` |
| Constant | `const x = 5` | `const x = 5` (compile-time) |
| Final | N/A | `final x = 5` (runtime constant) |
| Nullable | Always nullable | `int? x = null` (explicit) |
| Array | `[1, 2, 3]` | `List<int> x = [1, 2, 3]` |
| Object | `{key: value}` | `Map<String, int> x = {"key": 1}` |
| Async | `async/await` | `Future<T>` + `async/await` |
| Promise | `Promise<T>` | `Future<T>` |
| Class | `class X {}` | `class X {}` (very similar) |
| Arrow | `() => value` | `() => value` (same!) |
| Optional param | `{x, y}` | `{int? x, int? y}` |
| Null check | `x?.method()` | `x?.method()` (same!) |
| Default | `x ?? "default"` | `x ?? "default"` (same!) |

---

## Quick Tips

### Common Mistakes

❌ **Don't do this:**
```dart
String name = nullableString;  // Error if nullable
state.value++;                 // Doesn't rebuild
```

✅ **Do this:**
```dart
String name = nullableString ?? "default";
state = state.copyWith(value: state.value + 1);
```

### Best Practices

1. **Use `final` by default** - Only use `var` when needed
2. **Prefer named parameters** - Makes code more readable
3. **Use `ref.watch()` for data that should rebuild** - Use `ref.read()` for actions
4. **Handle all AsyncValue states** - Always use `.when()` with data/loading/error
5. **Use `const` for widgets** - Helps performance

### Useful Operators

```dart
// Null-aware cascade
doc?.update(title: "New");

// Spread operator
final combined = [...list1, ...list2];

// Collection if
final items = [
  "a",
  if (condition) "b",
  for (var item in list) item.toUpperCase(),
];

// Null-aware assignment
value ??= defaultValue;  // Assign if null
```

---

## Flutter DevTools

```bash
# Run with DevTools
flutter run

# Then open DevTools in browser:
# - Widget inspector (see widget tree)
# - Performance profiler
# - Memory profiler
# - Network inspector
```

---

## Debugging Tips

```dart
// Print debug info
print("Debug: $value");
debugPrint("Debug: $value");  // Better for Flutter

// Breakpoints
// Set breakpoints in IDE (VS Code, Android Studio)

// Assertions
assert(condition, "Message if false");

// Logger (used in this codebase)
final logger = Logger();
logger.d("Debug message");
logger.i("Info message");
logger.w("Warning message");
logger.e("Error message");
```

---

Keep this handy while exploring the codebase! 📚

