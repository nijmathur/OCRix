// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncQueueItem _$SyncQueueItemFromJson(Map<String, dynamic> json) =>
    _SyncQueueItem(
      id: json['id'] as String,
      action: json['action'] as String,
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as String,
      data: json['data'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: (json['retryCount'] as num).toInt(),
      lastRetryAt: json['lastRetryAt'] == null
          ? null
          : DateTime.parse(json['lastRetryAt'] as String),
      status: $enumDecode(_$SyncStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$SyncQueueItemToJson(_SyncQueueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'resourceType': instance.resourceType,
      'resourceId': instance.resourceId,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'retryCount': instance.retryCount,
      'lastRetryAt': instance.lastRetryAt?.toIso8601String(),
      'status': _$SyncStatusEnumMap[instance.status]!,
    };

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.processing: 'processing',
  SyncStatus.completed: 'completed',
  SyncStatus.failed: 'failed',
};
