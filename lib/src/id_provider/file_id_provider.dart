import 'dart:io';

import 'id_generator.dart';
import 'id_provider.dart';

class FileIdProvider implements IdProvider {
  static const String DEVICE_ID_FILE = 'anylogger_device_id';
  static const int _ID_LENGTH = 10;

  String? _deviceId;
  String? _sessionId;
  bool _initialized = false;

  // Flutter apps MUST set this or logging will fail when using %did
  static Future<Directory> Function()? getAppDocumentsDirectoryFnc;

  @override
  Future<void> initialize() async {
    if (_initialized && _deviceId != null) {
      _sessionId = _generateSessionId();
      return;
    }

    try {
      _deviceId = await _loadOrCreateDeviceId();
    } catch (e) {
      rethrow;
    }

    _sessionId = _generateSessionId();
    _initialized = true;
  }

  @override
  void initializeSync() {
    if (_initialized && _deviceId != null) {
      _sessionId = _generateSessionId();
      return;
    }

    // In Flutter environment, this should never be called
    // The check happens in LoggerFactory now
    try {
      _deviceId = _loadOrCreateDeviceIdSync();
    } catch (e) {
      rethrow;
    }

    _sessionId = _generateSessionId();
    _initialized = true;
  }

  Future<String> _loadOrCreateDeviceId() async {
    final dir = await _getStorageDirectory();
    final file = File('${dir.path}/$DEVICE_ID_FILE');

    if (await file.exists()) {
      final id = await file.readAsString();
      if (id.isNotEmpty) return id.trim();
    }

    final newId = IdGenerator.generateBase36Id(_ID_LENGTH);
    await dir.create(recursive: true);
    await file.writeAsString(newId);
    return newId;
  }

  String _loadOrCreateDeviceIdSync() {
    final dir = Directory('.anylogger');
    final file = File('${dir.path}/$DEVICE_ID_FILE');

    if (file.existsSync()) {
      final id = file.readAsStringSync();
      if (id.isNotEmpty) return id.trim();
    }

    final newId = IdGenerator.generateBase36Id(_ID_LENGTH);
    dir.createSync(recursive: true);
    file.writeAsStringSync(newId);
    return newId;
  }

  Future<Directory> _getStorageDirectory() async {
    if (getAppDocumentsDirectoryFnc != null) {
      final appDir = await getAppDocumentsDirectoryFnc!();
      return Directory('${appDir.path}/anylogger');
    }
    return Directory('.anylogger');
  }

  String _generateSessionId() => IdGenerator.generateBase36Id(_ID_LENGTH);

  @override
  String? get deviceId => _deviceId;

  @override
  String? get sessionId => _sessionId;

  @override
  bool get isInitialized => _initialized;

  @override
  void regenerateSessionId() {
    _sessionId = _generateSessionId();
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
