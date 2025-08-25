// ============================================================
// memory_id_provider.dart - In-memory implementation
// ============================================================

import 'dart:math';

import '../../any_logger.dart';
import 'id_provider.dart';

/// In-memory ID provider that doesn't persist IDs
/// Perfect for:
/// - Testing environments
/// - Applications that don't need persistent device IDs
class MemoryIdProvider implements IdProvider {
  static const int _ID_LENGTH = 10;
  String? _deviceId;
  String? _sessionId;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _deviceId ??=  IdGenerator.generateBase36Id(_ID_LENGTH);
    _sessionId = IdGenerator.generateBase36Id(_ID_LENGTH);
    _initialized = true;
  }

  @override
  void initializeSync() {
    _deviceId ??= IdGenerator.generateBase36Id(_ID_LENGTH);
    _sessionId = IdGenerator.generateBase36Id(_ID_LENGTH);
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
    _sessionId = IdGenerator.generateBase36Id(_ID_LENGTH);
    _deviceId ??= IdGenerator.generateBase36Id(_ID_LENGTH);
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
}
