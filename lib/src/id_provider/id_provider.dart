// ============================================================
// id_provider.dart - Abstract interface for ID management
// ============================================================

/// Abstract interface for managing device and session identification
abstract class IdProvider {
  /// Get the device ID (stable across app launches)
  String? get deviceId;

  /// Get the session ID (unique per app launch)
  String? get sessionId;

  bool get isInitialized;

  /// Initialize device and session IDs asynchronously
  Future<void> initialize();

  /// Initialize synchronously (for console-only loggers)
  void initializeSync();

  /// Generate a new session ID (called on each init)
  void regenerateSessionId();

  /// Reset all IDs (mainly for testing)
  void reset();

  /// Reset session ID only
  void resetSession();
}
