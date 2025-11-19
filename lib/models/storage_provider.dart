import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'storage_provider.g.dart';

@JsonSerializable()
class StorageProvider extends Equatable {
  final String id;
  final String name;
  final StorageProviderType type;
  final bool isEnabled;
  final Map<String, dynamic> configuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StorageProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.isEnabled,
    required this.configuration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StorageProvider.fromJson(Map<String, dynamic> json) =>
      _$StorageProviderFromJson(json);
  Map<String, dynamic> toJson() => _$StorageProviderToJson(this);

  @override
  List<Object?> get props =>
      [id, name, type, isEnabled, configuration, createdAt, updatedAt];
}

enum StorageProviderType {
  local,
  googleDrive,
  oneDrive,
  dropbox,
  box,
}

extension StorageProviderTypeExtension on StorageProviderType {
  String get displayName {
    switch (this) {
      case StorageProviderType.local:
        return 'Local Storage';
      case StorageProviderType.googleDrive:
        return 'Google Drive';
      case StorageProviderType.oneDrive:
        return 'OneDrive';
      case StorageProviderType.dropbox:
        return 'Dropbox';
      case StorageProviderType.box:
        return 'Box';
    }
  }

  String get iconName {
    switch (this) {
      case StorageProviderType.local:
        return 'storage';
      case StorageProviderType.googleDrive:
        return 'cloud';
      case StorageProviderType.oneDrive:
        return 'cloud';
      case StorageProviderType.dropbox:
        return 'cloud';
      case StorageProviderType.box:
        return 'cloud';
    }
  }

  bool get isCloudProvider {
    return this != StorageProviderType.local;
  }
}
