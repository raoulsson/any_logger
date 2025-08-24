import 'dart:io';

import 'id_generator.dart';
import 'id_provider.dart';

class AnyLoggerFileIdProvider implements IdProvider {
  static const String DEVICE_ID_FILE = 'anylogger_device_id';
  static const int _ID_LENGTH = 8;

  String? _deviceId;
  String? _sessionId;
  bool _initialized = false;

  // Flutter apps MUST set this or logging will fail
  static Future<Directory> Function()? getAppDocumentsDirectory;

  @override
  Future<void> initialize() async {
    if (_initialized && _deviceId != null) {
      _sessionId = _generateSessionId();
      return;
    }

    // Check for Flutter WITHOUT path_provider FIRST
    if (_isFlutterApp() && getAppDocumentsDirectory == null) {
      _failWithPathProviderRequired('path_provider not configured');
    }

    try {
      _deviceId = await _loadOrCreateDeviceId();
    } catch (e) {
      // If we get here on Flutter, something else is wrong
      if (_isFlutterApp()) {
        _failWithPathProviderRequired(e);
      }
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

    if (_isFlutterApp()) {
      throw StateError('Flutter requires async initialization. Use: await LoggerFactory.init(...)');
    }

    try {
      _deviceId = _loadOrCreateDeviceIdSync();
    } catch (e) {
      rethrow;
    }

    _sessionId = _generateSessionId();
    _initialized = true;
  }

  bool _isFlutterApp() {
    try {
      // This will work in a Flutter app, but throw on other platforms
      // If it throws, it's not a Flutter app
      // We can also check for path_provider existence
      return getAppDocumentsDirectory != null;
    } catch (e) {
      return false;
    }
  }

  Never _failWithPathProviderRequired(dynamic error) {
    throw StateError('''

════════════════════════════════════════════════════════════════════════════════
🚨 LOGGING DISABLED: path_provider Not Configured
add dependency to pubspec.yaml:
     path_provider: ^2.1.1
and set before LoggerFactory.init(...):
      AnyLoggerFileIdProvider.getAppDocumentsDirectory = getApplicationDocumentsDirectory;
════════════════════════════════════════════════════════════════════════════════
Your Flutter app REQUIRES path_provider to use device/session IDs (%did, %sid).

Step 1: Add to pubspec.yaml
   dependencies:
     path_provider: ^2.1.1

Step 2: Run command
   flutter pub get

Step 3: Add 2 lines to main.dart

   import 'package:path_provider/path_provider.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // ADD THIS LINE:
     AnyLoggerFileIdProvider.getAppDocumentsDirectory = getApplicationDocumentsDirectory;
     
     await LoggerFactory.init(yourConfig);
     runApp(MyApp());
   }

ALTERNATIVE: Remove %did and %sid from your log format.

Error: $error
════════════════════════════════════════════════════════════════════════════════
''');
  }

  Future<String> _loadOrCreateDeviceId() async {
    final dir = await _getStorageDirectory();
    final file = File('${dir.path}/$DEVICE_ID_FILE');

    if (await file.exists()) {
      final id = await file.readAsString();
      if (id.isNotEmpty) return id.trim();
    }

    final newId = IdGenerator.generateBase58Id(_ID_LENGTH);
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

    final newId = IdGenerator.generateBase58Id(_ID_LENGTH);
    dir.createSync(recursive: true);
    file.writeAsStringSync(newId);
    return newId;
  }

  Future<Directory> _getStorageDirectory() async {
    if (getAppDocumentsDirectory != null) {
      final appDir = await getAppDocumentsDirectory!();
      return Directory('${appDir.path}/anylogger');
    }
    return Directory('.anylogger');
  }

  String _generateSessionId() => IdGenerator.generateBase58Id(_ID_LENGTH);

  @override
  String? get deviceId => _deviceId;

  @override
  String? get sessionId => _sessionId;

  @override
  bool get isInitialized => _initialized;

  @override
  void regenerateSessionId() {
    _sessionId = _generateSessionId();
    _deviceId ??= IdGenerator.generateBase58Id(_ID_LENGTH);
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
