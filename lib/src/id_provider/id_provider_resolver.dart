import 'dart:io';

import '../../any_logger.dart';

class IdProviderResolver {
  static ({bool deviceIdNeeded, bool sessionIdNeeded}) analyzeRequirements(
      dynamic source) {
    bool deviceIdNeeded = false;
    bool sessionIdNeeded = false;

    // Handle List<Appender>
    if (source is List<Appender>) {
      for (var appender in source) {
        final format = appender.format;
        if (format.contains('%did')) deviceIdNeeded = true;
        if (format.contains('%sid')) sessionIdNeeded = true;
      }
    }
    // Handle Map<String, dynamic> JSON config
    else if (source is Map<String, dynamic>) {
      if (source.containsKey('appenders')) {
        for (var appender in source['appenders']) {
          final format = appender['format'] as String?;
          if (format != null) {
            if (format.contains('%did')) deviceIdNeeded = true;
            if (format.contains('%sid')) sessionIdNeeded = true;
          }
        }
      }
    }

    return (deviceIdNeeded: deviceIdNeeded, sessionIdNeeded: sessionIdNeeded);
  }

  /// Determine which provider to use based on requirements
  static IdProvider resolveProvider({
    required bool deviceIdNeeded,
    required bool sessionIdNeeded,
    required Future<Directory> Function()? getAppDocumentsDirectoryFnc,
  }) {
    // No IDs needed
    if (!deviceIdNeeded && !sessionIdNeeded) {
      return NullIdProvider();
    }

    final isFlutter = _isFlutterApp();

    if (isFlutter) {
      if (deviceIdNeeded) {
        if (getAppDocumentsDirectoryFnc == null) {
          throw StateError(_getPathProviderErrorMessage());
        }
        FileIdProvider.getAppDocumentsDirectoryFnc =
            getAppDocumentsDirectoryFnc;
        return FileIdProvider();
      } else if (sessionIdNeeded) {
        // Only session ID needed on Flutter
        return MemoryIdProvider();
      }
    } else {
      // Non-Flutter app - use file provider
      return FileIdProvider();
    }

    // Fallback
    return NullIdProvider();
  }

  /// Get a one-line debug summary
  static String getDebugSummary({
    required bool deviceIdNeeded,
    required bool sessionIdNeeded,
    required Future<Directory> Function()? getAppDocumentsDirectoryFnc,
  }) {
    final isFlutter = _isFlutterApp();
    final platform = isFlutter ? "Flutter" : "Dart";

    final ids =
        [if (deviceIdNeeded) '%did', if (sessionIdNeeded) '%sid'].join('+');

    String providerName;
    if (!deviceIdNeeded && !sessionIdNeeded) {
      providerName = "NullIdProvider";
    } else if (isFlutter && deviceIdNeeded) {
      providerName = getAppDocumentsDirectoryFnc != null
          ? "FileIdProvider"
          : "ERROR-needs-path_provider";
    } else if (isFlutter && sessionIdNeeded) {
      providerName = "MemoryIdProvider";
    } else {
      providerName = "FileIdProvider";
    }

    return 'Platform: $platform | IDs: ${ids.isEmpty ? "none" : ids} | Provider: $providerName';
  }

  static bool _isFlutterApp() {
    return const bool.fromEnvironment('dart.library.ui', defaultValue: false);
  }

  static String _getPathProviderErrorMessage() {
    return '''
════════════════════════════════════════════════════════════════════════════════
🚨 LOGGING DISABLED: path_provider Not Configured for Device ID (%did)
════════════════════════════════════════════════════════════════════════════════

Your Flutter app uses %did (device ID) which requires persistent storage.

OPTION 1: Configure path_provider (Recommended)
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
       LoggerFactory.setGetAppDocumentsDirectoryFnc(getApplicationDocumentsDirectory);
       
       await LoggerFactory.init(yourConfig);
       runApp(MyApp());
     }

OPTION 2: Use Memory Provider (IDs won't persist)
  LoggerFactory.setIdProvider(MemoryIdProvider());

OPTION 3: Remove %did from your log format
  Use only %sid for session tracking, or remove both.

════════════════════════════════════════════════════════════════════════════════
''';
  }
}
