# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

For detailed architecture and patterns, see `docs/guides/CLAUDE.md`.

## Quick Reference

**Project**: OCRix - Privacy-first document scanner and search app (Flutter/Dart)

**Key commands**:
- `flutter pub get` - Install dependencies
- `flutter test` - Run tests
- `flutter analyze` - Lint/analyze
- `dart format .` - Format code
- `dart run build_runner build` - Regenerate `.g.dart` files after modifying `@JsonSerializable()` models
- `flutter build apk --release` - Build Android APK

## Architecture

```
Presentation (UI) → State Management (Providers/Riverpod) → Services → Data (SQLite/Storage)
```

- **Services** extend `BaseService`, implement interfaces from `lib/core/interfaces/`
- **State**: Riverpod providers in `lib/providers/`
- **Models**: `lib/models/` with `json_serializable` (commit `.g.dart` files)
- **Database**: SQLite with FTS5 search, encryption at rest, audit triggers
- **Auth**: Google Sign-In + optional biometric

## Key Patterns

- Services inject troubleshooting logger via `setTroubleshootingLogger()`
- Database operations must set user ID context for audit triggers
- All new services need: interface, implementation extending `BaseService`, Riverpod provider, initialization in `AppInitializer`
- Three-tier logging: console (dev), file-based troubleshooting, tamper-proof audit DB

## Privacy-First Principles

- All OCR processing on-device
- No analytics or tracking
- User controls storage locations
- Explicit consent for cloud operations
