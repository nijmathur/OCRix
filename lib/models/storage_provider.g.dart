// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageProvider _$StorageProviderFromJson(Map<String, dynamic> json) =>
    StorageProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$StorageProviderTypeEnumMap, json['type']),
      isEnabled: json['isEnabled'] as bool,
      configuration: json['configuration'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$StorageProviderToJson(StorageProvider instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$StorageProviderTypeEnumMap[instance.type]!,
      'isEnabled': instance.isEnabled,
      'configuration': instance.configuration,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$StorageProviderTypeEnumMap = {
  StorageProviderType.local: 'local',
  StorageProviderType.googleDrive: 'googleDrive',
  StorageProviderType.oneDrive: 'oneDrive',
  StorageProviderType.dropbox: 'dropbox',
  StorageProviderType.box: 'box',
};
