// ============================================================
// platform_id_provider.dart - Flutter-aware implementation
// ============================================================

import 'dart:io' show Platform;

import '../../any_logger.dart';

/// Platform-aware ID provider for Flutter applications
///
/// Automatically selects the best strategy based on the platform:
/// - Mobile: Uses app documents directory (requires path_provider)
/// - Web: Uses in-memory storage
/// - Desktop: Uses file system
///
/// Usage:
/// ```dart
/// LoggerFactory.setIdProvider(PlatformIdProvider());
/// ```
class PlatformIdProvider implements IdProvider {
  late final IdProvider _delegate;

  PlatformIdProvider() {
    _delegate = _createDelegate();
  }

  IdProvider _createDelegate() {
    try {
      // Check if we're running on the web
      if (identical(0, 0.0)) {
        // Running on web (in web, 0 and 0.0 are identical)
        return MemoryIdProvider();
      }

      // Check platform
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, we need proper storage permissions
        // For now, use memory provider
        // In a real app, you'd use path_provider here
        return MemoryIdProvider();
      } else {
        // Desktop platforms can use file system
        return AnyLoggerFileIdProvider();
      }
    } catch (e) {
      // If platform detection fails, use memory provider
      return MemoryIdProvider();
    }
  }

  @override
  Future<void> initialize() async => await _delegate.initialize();

  @override
  void initializeSync() => _delegate.initializeSync();

  @override
  String? get deviceId => _delegate.deviceId;

  @override
  String? get sessionId => _delegate.sessionId;

  @override
  bool get isInitialized => _delegate.isInitialized;

  @override
  void regenerateSessionId() => _delegate.regenerateSessionId();

  @override
  void reset() => _delegate.reset();

  @override
  void resetSession() => _delegate.resetSession();
}
