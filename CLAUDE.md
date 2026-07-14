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
- `dart run build_runner build` - Regenerate `.freezed.dart` / `.g.dart` files after modifying models
- `flutter build apk --release` - Build Android APK

## Architecture

```
Presentation (UI) → State Management (Providers/Riverpod) → Services → Data (SQLite/Storage)
```

- **Services** extend `BaseService`, implement interfaces from `lib/core/interfaces/`
- **State**: Riverpod `Notifier<S>` / `AsyncNotifier<S>` providers in `lib/providers/`
- **Models**: `lib/models/` with **freezed** + `json_serializable` (commit `.freezed.dart` + `.g.dart` files)
- **Database**: SQLite v12, FTS5 search, `vendor` field encrypted, audit triggers
- **Auth**: Google Sign-In + optional biometric
- **Background tasks**: tracked via `BackgroundTaskNotifier` (`lib/providers/background_task_provider.dart`)

## Key Patterns

- Services inject troubleshooting logger via `setTroubleshootingLogger()` in provider factory
- Database init order: `DB.initialize()` → `Audit.initialize()` → `DB.setAuditLoggingService(audit)` — never reversed
- All new services: interface in `lib/core/interfaces/`, impl extending `BaseService`, Riverpod provider, init in `AppInitializer`
- Three-tier logging: console (dev), file-based troubleshooting, tamper-proof audit DB
- Mutations: capture `previousState = state` before try block; restore on error (no `AsyncValue.error()` on mutations)
- No singletons: never add `static final _instance` / `factory Foo() => _instance`

## Architectural Direction (consensus July 2026)

Do NOT do:
- Add singleton patterns to services
- Call `DatabaseService()` inside another service (use injected `IDatabaseService`)
- Use `StateNotifier` (use `Notifier`/`AsyncNotifier`)
- Use `Equatable` (use `freezed`)
- Fire-and-forget background tasks without `BackgroundTaskNotifier`

See `docs/guides/CLAUDE.md` § "Architectural Direction" for full rules and known limitations.

## Testing Policy

Write tests for core business logic and important paths. Do NOT write tests for unimportant or trivial paths.

**Write tests for:**
- State rollback / error recovery in providers (e.g. `scanDocument`, `scanMultiPageDocument`)
- Database atomicity — inserts that must touch multiple tables together
- Security-critical logic: encryption/decryption, audit chain integrity, checksum verification
- Complex service fallback chains (e.g. LLM → regex in `EntityExtractionService`)
- Data integrity constraints: cascade deletes, FK enforcement, FTS5 search correctness
- Non-obvious edge cases that have caused or could cause data loss or corruption

**Do NOT write tests for:**
- Simple getters / trivial mappings with no branching logic
- UI widget layout or styling details
- Boilerplate that is already covered by the framework (e.g. Riverpod provider wiring itself)
- Paths that duplicate coverage already provided by an existing test
- Error handling in paths that cannot realistically fail (e.g. wrapping a no-op)

When adding a new service or provider method, ask: *"could a bug here cause data loss, a security breach, or a broken user flow?"* If yes, write a test. If no, skip it.

## Documentation Update Policy

**Before every commit**, update any docs affected by the change:

| If you changed… | Update… |
|---|---|
| A new service, interface, or provider | `docs/guides/CLAUDE.md` (architecture section) |
| Implementation status of a feature | `docs/requirements/requirements.md` §7 |
| A new architectural pattern or rule | `CLAUDE.md` (this file) + `docs/guides/CLAUDE.md` |
| Refactoring / tech debt resolution | `docs/architecture/REFACTORING_SUMMARY.md` |
| A screen or user-visible workflow | `docs/guides/CLAUDE.md` (screens / data flows) |
| Test count or testing patterns | `MEMORY.md` (auto-memory) |

If a code commit touches `lib/` or `test/` but **no** `docs/` file is staged, the pre-commit hook will ask you to confirm. Either update the relevant doc(s) and re-stage, or confirm that no doc change is needed.

## Documentation Map

| File | Purpose |
|---|---|
| `CLAUDE.md` (this file) | Quick reference — architecture, patterns, testing policy |
| `docs/guides/CLAUDE.md` | Detailed architecture, data flows, screen list, security, all dev workflows |
| `docs/guides/EXPLORATION_ROADMAP.md` | Step-by-step codebase walkthrough for onboarding |
| `docs/requirements/requirements.md` | Product requirements + §7 implementation status |
| `docs/architecture/ARCHITECTURAL_REVIEW.md` | Nov 2025 SOLID/DRY review (all issues resolved July 2026) |
| `docs/architecture/REFACTORING_SUMMARY.md` | What was refactored and what remains pending |
| `docs/architecture/REFACTORING_PLAN.md` | Historical plan (complete) |
| `docs/session_notes.md` | Historical session log (Jan 2026, superseded) |

## Privacy-First Principles

- All OCR processing on-device
- No analytics or tracking
- User controls storage locations
- Explicit consent for cloud operations
