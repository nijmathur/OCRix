import 'package:mocktail/mocktail.dart';
import 'package:ocrix/core/interfaces/audit_database_service_interface.dart';
import 'package:ocrix/core/interfaces/camera_service_interface.dart';
import 'package:ocrix/core/interfaces/database_service_interface.dart';
import 'package:ocrix/core/interfaces/encryption_service_interface.dart';
import 'package:ocrix/core/interfaces/image_processing_service_interface.dart';
import 'package:ocrix/core/interfaces/log_file_service_interface.dart';
import 'package:ocrix/core/interfaces/log_formatter_interface.dart';
import 'package:ocrix/core/interfaces/log_rotation_service_interface.dart';
import 'package:ocrix/core/interfaces/ocr_service_interface.dart';
import 'package:ocrix/core/interfaces/storage_provider_service_interface.dart';
import 'package:ocrix/core/interfaces/troubleshooting_logger_interface.dart';

class MockDatabaseService extends Mock implements IDatabaseService {}

class MockEncryptionService extends Mock implements IEncryptionService {}

class MockOCRService extends Mock implements IOCRService {}

class MockCameraService extends Mock implements ICameraService {}

class MockStorageProviderService extends Mock
    implements IStorageProviderService {}

class MockImageProcessingService extends Mock
    implements IImageProcessingService {}

class MockAuditDatabaseService extends Mock implements IAuditDatabaseService {}

class MockTroubleshootingLogger extends Mock implements ITroubleshootingLogger {}

class MockLogFileService extends Mock implements ILogFileService {}

class MockLogFormatter extends Mock implements ILogFormatter {}

class MockLogRotationService extends Mock implements ILogRotationService {}
