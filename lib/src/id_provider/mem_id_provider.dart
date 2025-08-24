// ============================================================
// memory_id_provider.dart - In-memory implementation
// ============================================================

import 'dart:math';

import 'id_provider.dart';

/// In-memory ID provider that doesn't persist IDs
/// Perfect for:
/// - Flutter Web applications
/// - Testing environments
/// - Applications that don't need persistent device IDs
class MemoryIdProvider implements IdProvider {
  String? _deviceId;
  String? _sessionId;
  bool _initialized = false;
  final Random _random = Random();

  @override
  Future<void> initialize() async {
    _deviceId ??= _generateId('device');
    _sessionId = _generateId('session');
    _initialized = true;
  }

  @override
  void initializeSync() {
    _deviceId ??= _generateId('device');
    _sessionId = _generateId('session');
    _initialized = true;
  }

  @override
  String? get deviceId => _deviceId;

  @override
  String? get sessionId => _sessionId;

  @override
  bool get isInitialized => _initialized;

  @override
  void regenerateSessionId() {
    _sessionId = _generateId('session');
    _deviceId ??= _generateId('device');
  }

  @override
  void reset() {
    _deviceId = null;
    _sessionId = null;
    _initialized = false;
  }

  @override
  void resetSession() {
    _sessionId = null;
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return '$prefix-${timestamp % 100000}-$random'
        .replaceAll('device-', 'd')
        .replaceAll('session-', 's')
        .substring(0, 8);
  }
}
