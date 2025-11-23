/// Interface for log rotation (SOLID - Interface Segregation)
abstract class ILogRotationService {
  /// Check if rotation is needed and perform it if necessary
  Future<void> checkAndRotate();

  /// Force rotation of logs
  Future<void> rotate();

  /// Get rotation interval
  Duration get rotationInterval;

  /// Set rotation interval
  void setRotationInterval(Duration interval);
}
