# OCRix

A privacy-first, cross-platform document scanner and organizer app built with Flutter. Scan documents, extract text with on-device OCR, and organize your documents with flexible storage options while maintaining complete control over your data.

## 🔒 Privacy-First Design

-   **Local Processing**: All OCR and document processing happens on your device
-   **Your Data, Your Control**: Choose where to store your documents (local or cloud)
-   **End-to-End Encryption**: All data encrypted with industry-standard AES-256
-   **No Tracking**: No analytics, ads, or data collection
-   **Complete Transparency**: Open source with auditable code

## ✨ Key Features

### 📱 Smart Document Scanning

-   **Camera Capture**: High-quality document scanning with your device camera
-   **Gallery Import**: Import existing images from your photo library
-   **On-Device OCR**: Extract text using Google ML Kit (Android) and Apple Vision (iOS)
-   **Smart Categorization**: Automatically categorize documents (receipts, contracts, etc.)
-   **Text Editing**: Edit extracted text before saving

### 🔍 Powerful Search & Organization

-   **Full-Text Search**: Find documents instantly with local FTS5 search
-   **Smart Filtering**: Filter by document type, date, tags, or content
-   **Custom Tags**: Organize documents with your own tags
-   **Metadata Management**: Add notes, locations, and custom metadata

### ☁️ Flexible Storage Options

-   **Local Storage**: Keep everything on your device for maximum privacy
-   **Cloud Sync**: Optional sync with Google Drive, OneDrive, and more
-   **Mix & Match**: Store metadata locally and files in the cloud, or vice versa
-   **Easy Migration**: Move between storage providers anytime

### 🛡️ Security & Privacy

-   **AES-256 Encryption**: All data encrypted at rest and in transit
-   **Biometric Authentication**: Secure app access with fingerprint/face recognition
-   **Audit Trail**: Complete logging of all data operations
-   **Right to Erasure**: Permanently delete any document or all data
-   **No Cloud Analytics**: Zero data collection or tracking

## 🚀 Getting Started

### Prerequisites

-   Flutter SDK 3.4.1 or higher
-   Android Studio (for Android development)
-   Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**

    ```bash
    git clone <repository-url>
    cd privacy_document_scanner
    ```

2. **Install dependencies**

    ```bash
    flutter pub get
    ```

3. **Generate code**

    ```bash
    dart run build_runner build
    ```

4. **Run the app**
    ```bash
    flutter run
    ```

### Build for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 📱 Supported Platforms

-   **Android**: API level 21+ (Android 5.0)
-   **iOS**: iOS 12.0+
-   **Web**: Modern browsers with WebAssembly support
-   **Windows**: Windows 10+
-   **macOS**: macOS 10.14+
-   **Linux**: Ubuntu 18.04+

## 🏗️ Architecture

The app follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │   Screens   │ │   Widgets   │ │  Navigation │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   State Management                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │  Providers  │ │  Notifiers  │ │   States    │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │   Services  │ │   Models    │ │   Utils     │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │  Database   │ │   Storage   │ │   Network   │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### Core Services

-   **DatabaseService**: Manages SQLite database with encryption
-   **OCRService**: Handles text extraction using Google ML Kit
-   **CameraService**: Manages camera operations and image capture
-   **EncryptionService**: Provides AES-256 encryption and biometric auth
-   **StorageProviderService**: Abstracts storage operations across providers

## 🔧 Technology Stack

### Frontend

-   **Flutter**: Cross-platform UI framework
-   **Dart**: Programming language
-   **Riverpod**: State management
-   **Material Design**: UI components

### Backend Services

-   **SQLite**: Local database with FTS5 search
-   **Google ML Kit**: On-device OCR
-   **Camera**: Document capture
-   **Encryption**: AES-256 encryption

### Cloud Integration

-   **Google Drive**: Cloud storage provider
-   **OneDrive**: Cloud storage provider (planned)
-   **OAuth2**: Authentication
-   **REST APIs**: Provider integration

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:

-   **[Requirements](docs/requirements/requirements.md)**: Complete functional and technical requirements
-   **[Architecture](docs/architecture/system-architecture.md)**: System design and architecture
-   **[API Documentation](docs/api/service-interfaces.md)**: Service interfaces and data models
-   **[User Guide](docs/user-guide/getting-started.md)**: User documentation and guides
-   **[Deployment](docs/deployment/build-instructions.md)**: Build and deployment instructions

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/widget_test.dart
flutter test integration_test/

# Run tests with coverage
flutter test --coverage
```

## 🔒 Security Features

### Data Protection

-   **Encryption at Rest**: All local data encrypted with AES-256
-   **Encryption in Transit**: All network communications use TLS
-   **Secure Key Storage**: Encryption keys stored in secure storage
-   **Biometric Protection**: Optional fingerprint/face recognition

### Privacy Controls

-   **Local-First**: All operations work offline
-   **Explicit Consent**: User controls all data sharing
-   **Audit Trail**: Complete logging of all operations
-   **Right to Erasure**: Complete data deletion capabilities

### No Data Collection

-   **No Analytics**: No usage data collection
-   **No Tracking**: No user behavior tracking
-   **No Ads**: No advertising or third-party tracking
-   **Open Source**: Fully auditable code

## 🚀 Performance

-   **Instant Search**: Local FTS5 search for fast results
-   **Optimized Storage**: Efficient database and file management
-   **Background Sync**: Non-blocking sync operations
-   **Memory Efficient**: Optimized for older devices

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Standards

-   Follow Dart/Flutter style guidelines
-   Write comprehensive tests
-   Document all public APIs
-   Ensure privacy and security compliance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### For Users

-   Check the [User Guide](docs/user-guide/getting-started.md) for help
-   Review the [Troubleshooting](docs/user-guide/getting-started.md#troubleshooting) section
-   Contact support for additional help

### For Developers

-   Review the [API Documentation](docs/api/service-interfaces.md)
-   Check the [Architecture](docs/architecture/system-architecture.md) documentation
-   Follow the [Build Instructions](docs/deployment/build-instructions.md)

## 📈 Roadmap

### ✅ Completed Features

-   Core document scanning and OCR
-   Local storage with encryption
-   Google Drive integration
-   Full-text search
-   Privacy audit logging
-   Cross-platform support

### 🚧 In Progress

-   OneDrive integration
-   Advanced analytics
-   Performance optimization
-   Enhanced security features

### 📋 Planned Features

-   AI-powered categorization
-   Bulk operations
-   Advanced export options
-   Third-party integrations
-   Mobile app stores deployment

## 🙏 Acknowledgments

-   **Google ML Kit** for on-device OCR capabilities
-   **Flutter Team** for the excellent cross-platform framework
-   **Privacy-focused community** for inspiration and feedback

---

**Version**: 1.0.0  
**Last Updated**: January 2024  
**Status**: Complete and Ready for Use

Built with ❤️ and 🔒 for privacy-conscious users.
