import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_provider.freezed.dart';
part 'storage_provider.g.dart';

@freezed
abstract class StorageProvider with _$StorageProvider {
  const factory StorageProvider({
    required String id,
    required String name,
    required StorageProviderType type,
    required bool isEnabled,
    required Map<String, dynamic> configuration,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StorageProvider;

  factory StorageProvider.fromJson(Map<String, dynamic> json) =>
      _$StorageProviderFromJson(json);
}

enum StorageProviderType { local, googleDrive, oneDrive, dropbox, box }

extension StorageProviderTypeExtension on StorageProviderType {
  String get displayName => switch (this) {
    StorageProviderType.local => 'Local Storage',
    StorageProviderType.googleDrive => 'Google Drive',
    StorageProviderType.oneDrive => 'OneDrive',
    StorageProviderType.dropbox => 'Dropbox',
    StorageProviderType.box => 'Box',
  };

  String get iconName => switch (this) {
    StorageProviderType.local => 'storage',
    StorageProviderType.googleDrive => 'cloud',
    StorageProviderType.oneDrive => 'cloud',
    StorageProviderType.dropbox => 'cloud',
    StorageProviderType.box => 'cloud',
  };

  bool get isCloudProvider {
    return this != StorageProviderType.local;
  }
}
