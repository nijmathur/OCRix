# GitHub Actions Workflows

This directory contains the CI/CD workflows for the OCRix project.

## Available Workflows

### 1. Test and Coverage (`test-and-coverage.yml`)
**Triggers:** Push and PR to `main`, `develop`

**Purpose:** Run unit tests and generate coverage reports

**Features:**
- Runs Flutter tests with coverage
- Generates HTML coverage reports
- Uploads coverage to Codecov
- Comments on PRs with coverage summary
- Caches Flutter dependencies for faster runs

**Artifacts:**
- Coverage reports (30 days retention)

---

### 2. Android Build (`android-build.yml`)
**Triggers:** Push to any branch, PR to `main`, `develop`

**Purpose:** Build and validate Android APKs

**Features:**
- Builds both debug and release APKs
- Validates ProGuard rules
- Runs Flutter analyze
- Caches Gradle and Flutter dependencies
- Comments on PRs with build information

**Artifacts:**
- Debug APK (7 days retention)
- Release APK (30 days retention)

---

### 3. Code Quality (`code-quality.yml`)
**Triggers:** Push to any branch, PR to `main`, `develop`

**Purpose:** Enforce code quality standards

**Checks:**
- Static analysis (`flutter analyze`)
- Code formatting (`dart format`)
- Dependency validation
- TODO/FIXME tracking

**Features:**
- Comments on PRs with quality report
- Caches Flutter dependencies

---

### 4. Security Scan (`security-scan.yml`)
**Triggers:**
- Push and PR to `main`, `develop`
- Weekly schedule (Mondays at 9am UTC)

**Purpose:** Detect security vulnerabilities

**Features:**
- CodeQL security analysis
- Dependency vulnerability scanning
- Weekly automated scans

**Artifacts:**
- Dependency audit report (30 days retention)

---

### 5. Release Build (`release.yml`)
**Triggers:**
- Git tags matching `v*.*.*` (e.g., v1.0.0)
- Manual workflow dispatch

**Purpose:** Create production releases

**Features:**
- Builds release APK and App Bundle (AAB)
- Runs tests before building
- Generates changelog from commits
- Creates GitHub release with artifacts
- Names files with version numbers

**Artifacts:**
- Release APK (90 days retention)
- Release App Bundle (90 days retention)

---

## Workflow Performance Optimizations

All workflows implement:
- ✅ Gradle dependency caching (~2-3 min savings)
- ✅ Flutter pub cache caching (~1-2 min savings)
- ✅ Flutter SDK caching (built-in)
- ✅ Parallel job execution where possible

## How to Use

### Running Tests Locally
```bash
flutter test --coverage
```

### Building APKs Locally
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

### Creating a Release
```bash
# Tag the commit
git tag v1.0.0
git push origin v1.0.0

# Or use GitHub UI to trigger manual release
```

### Code Quality Checks
```bash
# Analyze
flutter analyze

# Format
dart format lib/ test/

# Check formatting
dart format --set-exit-if-changed --output=none lib/ test/
```

## Required Secrets

Configure these in your GitHub repository settings:

- `CODECOV_TOKEN`: Token for Codecov integration (optional, for test-and-coverage workflow)

## Branch Protection Rules

Recommended settings for `main` branch:
- ✅ Require status checks to pass before merging
  - `Run Tests with Coverage`
  - `Build Android APK`
  - `Code Quality Checks`
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging

## Workflow Status Badges

Add these to your README.md:

```markdown
![Test and Coverage](https://github.com/nijmathur/OCRix/actions/workflows/test-and-coverage.yml/badge.svg)
![Android Build](https://github.com/nijmathur/OCRix/actions/workflows/android-build.yml/badge.svg)
![Code Quality](https://github.com/nijmathur/OCRix/actions/workflows/code-quality.yml/badge.svg)
![Security Scan](https://github.com/nijmathur/OCRix/actions/workflows/security-scan.yml/badge.svg)
```

## Troubleshooting

### Workflow fails with "Gradle daemon disappeared"
- This is usually a memory issue. The workflows use `--no-daemon` flag where applicable.

### Caches not working
- Check that `pubspec.lock` and Gradle files haven't changed
- Caches are scoped to branch, so different branches have different caches

### CodeQL analysis timeout
- This can happen on large codebases. The timeout is set appropriately for this project.

## Future Improvements

Potential additions:
- iOS build workflow (when iOS support is added)
- Integration test workflow
- Performance benchmarking
- Automated dependency updates (Dependabot)
- Deploy to Play Store workflow
