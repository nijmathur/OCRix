# OCRix UML Diagrams

This folder contains comprehensive UML diagrams documenting the OCRix application architecture, design, and workflows.

## Diagram Files

### 1. Class Diagrams

#### `class_diagram.puml` - Domain Model Class Diagram
Illustrates the core domain models and their relationships:
- **Document**: Main entity for scanned documents
- **DocumentPage**: Individual pages in multi-page documents
- **AuditLog**: Audit trail with chain linking
- **UserSettings**: User preferences and configuration
- **StorageProvider**: Cloud storage provider configuration
- **AuthUser**: User authentication information
- Enumerations: DocumentType, AuditAction, AuditLevel, StorageProviderType

#### `service_class_diagram.puml` - Service Layer Class Diagram
Shows the service interfaces and implementations:
- **Service Interfaces**: IDatabaseService, IOCRService, ICameraService, IEncryptionService, etc.
- **Service Implementations**: DatabaseService, OCRService, CameraService, EncryptionService, etc.
- **External Dependencies**: Google ML Kit, Flutter Camera, Secure Storage, Google APIs
- Design patterns: Singleton, Dependency Injection

### 2. Architecture Diagrams

#### `architecture_component_diagram.puml` - Component Architecture
Depicts the high-level architecture with clean separation of concerns:
- **Presentation Layer**: Screens and widgets
- **State Management Layer**: Riverpod providers and notifiers
- **Business Logic Layer**: Services, models, and utilities
- **Data Layer**: SQLite database, file system, external APIs

#### `state_management_diagram.puml` - State Management Diagram
Details the Riverpod state management architecture:
- **Notifiers**: DocumentNotifier, ScannerNotifier, AuthNotifier, etc.
- **Providers**: Service providers and state notifier providers
- **Dependencies**: How UI depends on notifiers, and notifiers depend on services

#### `deployment_diagram.puml` - Deployment Diagram
Shows the runtime deployment architecture:
- **User Device**: Flutter app components, local storage, hardware
- **Google Cloud Platform**: Google Sign-In, Google Drive APIs
- **Security**: On-device processing, encrypted storage

### 3. Sequence Diagrams

#### `sequence_document_scanning.puml` - Document Scanning Workflow
Step-by-step sequence for scanning a single-page document:
1. Camera initialization
2. Image capture
3. OCR text extraction
4. Document categorization
5. Database storage
6. Audit logging

#### `sequence_multi_page_scanning.puml` - Multi-Page Document Scanning
Workflow for scanning multi-page documents:
1. Enable multi-page mode
2. Capture multiple pages
3. Review captured pages
4. Process each page with OCR
5. Save as unified document with pages
6. Reset multi-page state

#### `sequence_authentication.puml` - Authentication & Authorization Workflow
Complete authentication flow:
1. App launch and auth check
2. Google Sign-In process
3. Biometric authentication (if enabled)
4. Sign out process
5. Audit logging for auth events

## How to View These Diagrams

### Option 1: PlantUML Online Editor
1. Go to [PlantUML Online Editor](http://www.plantuml.com/plantuml/uml/)
2. Copy the contents of any `.puml` file
3. Paste into the editor
4. The diagram will render automatically

### Option 2: VS Code Extension
1. Install the [PlantUML extension](https://marketplace.visualstudio.com/items?itemName=jebbs.plantuml)
2. Open any `.puml` file in VS Code
3. Press `Alt+D` to preview the diagram
4. Or right-click and select "Preview Current Diagram"

### Option 3: IntelliJ IDEA / Android Studio
1. Install the PlantUML integration plugin
2. Open any `.puml` file
3. The diagram will render in a preview pane

### Option 4: Command Line (with PlantUML installed)
```bash
# Install PlantUML (requires Java)
brew install plantuml  # macOS
sudo apt-get install plantuml  # Linux

# Generate PNG images
plantuml docs/uml/*.puml

# Generate SVG images
plantuml -tsvg docs/uml/*.puml
```

### Option 5: Docker
```bash
# Generate PNG images using Docker
docker run --rm -v $(pwd)/docs/uml:/data plantuml/plantuml -tpng /data/*.puml

# Generate SVG images
docker run --rm -v $(pwd)/docs/uml:/data plantuml/plantuml -tsvg /data/*.puml
```

## Diagram Relationships

```
class_diagram.puml ──────┐
                         ├──> Shows domain models
service_class_diagram.puml  │
                           └──> Shows services that work with models

architecture_component_diagram.puml ──> High-level architecture overview
                                    │
state_management_diagram.puml ─────┴──> Details state management layer

deployment_diagram.puml ──> Shows runtime deployment and infrastructure

sequence_document_scanning.puml ────┐
sequence_multi_page_scanning.puml ──┼──> Show key workflows using
sequence_authentication.puml ────────┘    components and services
```

## Key Architectural Patterns

These diagrams illustrate the following design patterns and principles:

1. **Clean Architecture**
   - Separation of concerns across layers
   - Dependency inversion through interfaces
   - Independent, testable components

2. **Repository Pattern**
   - DatabaseService acts as repository
   - Abstract data access

3. **State Management (Riverpod)**
   - Provider pattern for dependency injection
   - Reactive state updates
   - Automatic lifecycle management

4. **Singleton Pattern**
   - Services use singleton instances
   - Shown in service_class_diagram.puml

5. **Dependency Injection**
   - Constructor injection via Riverpod
   - Shown in state_management_diagram.puml

6. **Observer Pattern**
   - Providers notify UI of state changes
   - Shown in sequence diagrams

## Updating Diagrams

When the architecture changes:

1. Update the relevant `.puml` files
2. Regenerate diagrams if needed
3. Update this README if new diagrams are added
4. Ensure diagrams stay in sync with code

## PlantUML Syntax Reference

- [PlantUML Official Documentation](https://plantuml.com/)
- [PlantUML Class Diagram Guide](https://plantuml.com/class-diagram)
- [PlantUML Sequence Diagram Guide](https://plantuml.com/sequence-diagram)
- [PlantUML Component Diagram Guide](https://plantuml.com/component-diagram)
- [PlantUML Deployment Diagram Guide](https://plantuml.com/deployment-diagram)

## Contributing

When adding new features to OCRix:
1. Update existing diagrams to reflect changes
2. Create new diagrams if introducing new architectural components
3. Keep diagrams simple and focused
4. Add notes to explain complex interactions
5. Use consistent naming with the codebase

## License

These diagrams are part of the OCRix project and follow the same license as the main codebase.
