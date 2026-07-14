import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocrix/providers/background_task_provider.dart';

void main() {
  ProviderContainer createContainer() => ProviderContainer();

  group('BackgroundTaskNotifier', () {
    test('starts empty', () {
      final container = createContainer();
      addTearDown(container.dispose);
      expect(container.read(backgroundTaskNotifierProvider), isEmpty);
    });

    test('markRunning adds a running task', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      notifier.markRunning('doc1', BackgroundTaskType.vectorization);

      final tasks = container.read(backgroundTaskNotifierProvider);
      expect(tasks.length, 1);
      expect(tasks.first.documentId, 'doc1');
      expect(tasks.first.type, BackgroundTaskType.vectorization);
      expect(tasks.first.status, BackgroundTaskStatus.running);
      expect(tasks.first.isRunning, isTrue);
    });

    test('markRunning replaces existing task with same id', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      notifier.markRunning('doc1', BackgroundTaskType.vectorization);
      notifier.markFailed('doc1', BackgroundTaskType.vectorization, Exception('err'));
      notifier.markRunning('doc1', BackgroundTaskType.vectorization);

      final tasks = container.read(backgroundTaskNotifierProvider);
      expect(tasks.where((t) => t.documentId == 'doc1').length, 1);
      expect(tasks.first.status, BackgroundTaskStatus.running);
    });

    test('markCompleted transitions task to completed', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      notifier.markRunning('doc1', BackgroundTaskType.entityExtraction);
      notifier.markCompleted('doc1', BackgroundTaskType.entityExtraction);

      final tasks = container.read(backgroundTaskNotifierProvider);
      expect(tasks.first.status, BackgroundTaskStatus.completed);
      expect(tasks.first.isRunning, isFalse);
      expect(tasks.first.isFailed, isFalse);
    });

    test('markFailed sets error and failed status', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);
      final error = Exception('vectorization failed');

      notifier.markRunning('doc2', BackgroundTaskType.vectorization);
      notifier.markFailed('doc2', BackgroundTaskType.vectorization, error);

      final tasks = container.read(backgroundTaskNotifierProvider);
      expect(tasks.first.status, BackgroundTaskStatus.failed);
      expect(tasks.first.isFailed, isTrue);
      expect(tasks.first.error, error);
    });

    test('isAnyRunning reflects running tasks', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      expect(notifier.isAnyRunning, isFalse);

      notifier.markRunning('doc1', BackgroundTaskType.vectorization);
      expect(notifier.isAnyRunning, isTrue);

      notifier.markCompleted('doc1', BackgroundTaskType.vectorization);
      expect(notifier.isAnyRunning, isFalse);
    });

    test('failed returns only failed tasks', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      notifier.markRunning('doc1', BackgroundTaskType.vectorization);
      notifier.markCompleted('doc1', BackgroundTaskType.vectorization);
      notifier.markRunning('doc2', BackgroundTaskType.entityExtraction);
      notifier.markFailed('doc2', BackgroundTaskType.entityExtraction, 'err');

      expect(notifier.failed.length, 1);
      expect(notifier.failed.first.documentId, 'doc2');
    });

    test('clearCompleted removes completed tasks but keeps running and failed', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      notifier.markRunning('doc1', BackgroundTaskType.vectorization);
      notifier.markCompleted('doc1', BackgroundTaskType.vectorization);
      notifier.markRunning('doc2', BackgroundTaskType.entityExtraction);
      notifier.markRunning('doc3', BackgroundTaskType.vectorization);
      notifier.markFailed('doc3', BackgroundTaskType.vectorization, 'err');

      notifier.clearCompleted();

      final tasks = container.read(backgroundTaskNotifierProvider);
      expect(tasks.length, 2);
      expect(tasks.any((t) => t.documentId == 'doc1'), isFalse);
      expect(tasks.any((t) => t.documentId == 'doc2'), isTrue); // running
      expect(tasks.any((t) => t.documentId == 'doc3'), isTrue); // failed
    });

    test('multiple task types per document are independent', () {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(backgroundTaskNotifierProvider.notifier);

      notifier.markRunning('doc1', BackgroundTaskType.vectorization);
      notifier.markRunning('doc1', BackgroundTaskType.entityExtraction);

      final tasks = container.read(backgroundTaskNotifierProvider);
      expect(tasks.length, 2);
      expect(tasks.where((t) => t.documentId == 'doc1').length, 2);
    });
  });
}
