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
  List<Object?> get props => [
    id,
    name,
    type,
    isEnabled,
    configuration,
    createdAt,
    updatedAt,
  ];
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
