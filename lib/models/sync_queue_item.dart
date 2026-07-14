/// Sync Queue Item Model
/// Represents a pending cloud sync operation in the local queue.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue_item.freezed.dart';
part 'sync_queue_item.g.dart';

/// Status of a sync queue item
enum SyncStatus {
  pending,
  processing,
  completed,
  failed;

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

/// An item in the background sync queue
@freezed
abstract class SyncQueueItem with _$SyncQueueItem {
  const factory SyncQueueItem({
    required String id,

    /// 'upload' or 'delete'
    required String action,

    /// e.g. 'document'
    required String resourceType,
    required String resourceId,

    /// JSON payload with data needed to perform the action
    required String data,
    required DateTime createdAt,
    required int retryCount,
    DateTime? lastRetryAt,
    required SyncStatus status,
  }) = _SyncQueueItem;

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueItemFromJson(json);

  /// Deserialize from a SQLite row map
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      action: map['action'] as String,
      resourceType: map['resource_type'] as String,
      resourceId: map['resource_id'] as String,
      data: map['data'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      retryCount: map['retry_count'] as int,
      lastRetryAt: map['last_retry_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_retry_at'] as int)
          : null,
      status: SyncStatus.fromString(map['status'] as String),
    );
  }

  /// Serialize to a SQLite row map
  static Map<String, dynamic> toMap(SyncQueueItem item) {
    return {
      'id': item.id,
      'action': item.action,
      'resource_type': item.resourceType,
      'resource_id': item.resourceId,
      'data': item.data,
      'created_at': item.createdAt.millisecondsSinceEpoch,
      'retry_count': item.retryCount,
      'last_retry_at': item.lastRetryAt?.millisecondsSinceEpoch,
      'status': item.status.name,
    };
  }
}
