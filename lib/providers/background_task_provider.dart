import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_task_provider.freezed.dart';

enum BackgroundTaskType {
  vectorization,
  entityExtraction;

  String get displayName => switch (this) {
    vectorization => 'Vectorizing',
    entityExtraction => 'Extracting entities',
  };
}

enum BackgroundTaskStatus { running, completed, failed }

@freezed
abstract class BackgroundTask with _$BackgroundTask {
  const factory BackgroundTask({
    required String id,
    required String documentId,
    required BackgroundTaskType type,
    @Default(BackgroundTaskStatus.running) BackgroundTaskStatus status,
    Object? error,
  }) = _BackgroundTask;

  const BackgroundTask._();

  bool get isRunning => status == BackgroundTaskStatus.running;
  bool get isFailed => status == BackgroundTaskStatus.failed;
}

class BackgroundTaskNotifier extends Notifier<List<BackgroundTask>> {
  @override
  List<BackgroundTask> build() => const [];

  String _taskId(String documentId, BackgroundTaskType type) =>
      '${documentId}_${type.name}';

  void markRunning(String documentId, BackgroundTaskType type) {
    final id = _taskId(documentId, type);
    final task = BackgroundTask(id: id, documentId: documentId, type: type);
    state = [
      ...state.where((t) => t.id != id),
      task,
    ];
  }

  void markCompleted(String documentId, BackgroundTaskType type) {
    final id = _taskId(documentId, type);
    state = state
        .map((t) => t.id == id ? t.copyWith(status: BackgroundTaskStatus.completed) : t)
        .toList();
  }

  void markFailed(String documentId, BackgroundTaskType type, Object error) {
    final id = _taskId(documentId, type);
    state = state
        .map((t) => t.id == id
            ? t.copyWith(status: BackgroundTaskStatus.failed, error: error)
            : t)
        .toList();
  }

  /// Remove completed tasks from the list (keep running and failed)
  void clearCompleted() {
    state = state.where((t) => t.isRunning || t.isFailed).toList();
  }

  bool get isAnyRunning => state.any((t) => t.isRunning);
  List<BackgroundTask> get failed => state.where((t) => t.isFailed).toList();
}

final backgroundTaskNotifierProvider =
    NotifierProvider<BackgroundTaskNotifier, List<BackgroundTask>>(
      BackgroundTaskNotifier.new,
    );
