# OCRix

Privacy-first document scanner app built with Flutter. Scans documents, extracts text via on-device OCR, stores encrypted locally, syncs to Google Drive.

## Quick Start

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Project Structure

```
lib/
├── core/           # Interfaces, base classes, config, exceptions
├── models/         # Data models (Document, UserSettings, AuditLog)
├── services/       # Business logic (Database, OCR, Camera, Encryption)
├── providers/      # Riverpod state management
├── ui/
│   ├── screens/    # HomeScreen, ScannerScreen, SettingsScreen
│   └── widgets/    # Reusable UI components
└── utils/          # Constants, helpers
```

## Key Features

- **On-device OCR** - Google ML Kit, no cloud processing
- **Encrypted storage** - AES-256 encryption at rest
- **Full-text search** - SQLite FTS5
- **Cloud backup** - Google Drive (appDataFolder)
- **Audit logging** - Tamper-proof chain verification

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| State | Riverpod |
| Database | SQLite + FTS5 |
| OCR | Google ML Kit |
| Encryption | AES-256 + PBKDF2 |
| Cloud | Google Drive API |

## Documentation

- [REQUIREMENTS.md](./REQUIREMENTS.md) - Functional and non-functional requirements
- [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) - Complete technical documentation
