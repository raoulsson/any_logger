import 'dart:io';

import '../../any_logger.dart';

class IdProviderResolver {
  static bool isRunningAsUnitTest = false;
  static bool unitTestIsFlutterResultValue = false;

  static ({bool deviceIdNeeded, bool sessionIdNeeded, bool fileAppenderNeeded})
      analyzeRequirements(dynamic source) {
    bool deviceIdNeeded = false;
    bool sessionIdNeeded = false;
    bool fileAppenderNeeded = false;

    // Handle List<Appender>
    if (source is List<Appender>) {
      for (var appender in source) {
        final format = appender.format;
        if (format.contains('%did')) deviceIdNeeded = true;
        if (format.contains('%sid')) sessionIdNeeded = true;
        if (appender.getType() == 'FILE') fileAppenderNeeded = true;
        if (appender.getType() == 'EMAIL') fileAppenderNeeded = true;
        if (appender.getType() == 'EMAIL') deviceIdNeeded = true;
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
          final type = appender['type'] as String?;
          if (type?.toUpperCase() == 'FILE') fileAppenderNeeded = true;
          if (type?.toUpperCase() == 'EMAIL') fileAppenderNeeded = true;
          if (type?.toUpperCase() == 'EMAIL') deviceIdNeeded = true;
        }
      }
    }

    return (
      deviceIdNeeded: deviceIdNeeded,
      sessionIdNeeded: sessionIdNeeded,
      fileAppenderNeeded: fileAppenderNeeded
    );
  }

  /// Determine which provider to use based on requirements
  static IdProvider resolveProvider({
    required bool deviceIdNeeded,
    required bool sessionIdNeeded,
    required bool fileAppenderNeeded,
    required Future<Directory> Function()? getAppDocumentsDirectoryFnc,
  }) {
    final isFlutter = isFlutterApp();

    // Check if Flutter app needs path_provider for FILE appender
    if (isFlutter &&
        fileAppenderNeeded &&
        getAppDocumentsDirectoryFnc == null) {
      throw StateError(getFileOrEmailAppenderErrorMessage());
    }

    // No IDs needed
    if (!deviceIdNeeded && !sessionIdNeeded) {
      return NullIdProvider();
    }

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
    required bool fileAppenderNeeded,
    required Future<Directory> Function()? getAppDocumentsDirectoryFnc,
  }) {
    final isFlutter = isFlutterApp();
    final platform = isFlutter ? "Flutter" : "Dart";

    final features = [
      if (deviceIdNeeded) '%did',
      if (sessionIdNeeded) '%sid',
      if (fileAppenderNeeded) 'FILE',
      if (fileAppenderNeeded) 'EMAIL'
    ].join('+');

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

    // Add file appender status
    String fileStatus = "";
    if (fileAppenderNeeded) {
      if (isFlutter && getAppDocumentsDirectoryFnc == null) {
        fileStatus = " | FILE: ERROR-needs-path_provider";
      } else {
        fileStatus = " | FILE: OK";
      }
    }

    return 'Platform: $platform | Features: ${features.isEmpty ? "none" : features} | Provider: $providerName$fileStatus';
  }

  static bool isFlutterApp() {
    if (isRunningAsUnitTest) {
      return unitTestIsFlutterResultValue;
    }
    return const bool.fromEnvironment('dart.library.ui', defaultValue: false);
  }

  static String _getPathProviderErrorMessage() {
    return '''

════════════════════════════════════════════════════════════════════════════════
🚨 ANYLOGGER CONFIG ERROR: At least one of your appenders format strings contains
'%did' for device hash tracking. Running on Flutter, you need to:
════════════════════════════════════════════════════════════════════════════════
Add:
  path_provider: ^x.y.z // in pubspec.yaml
and call:
  LoggerFactory.setGetAppDocumentsDirectoryFnc(getApplicationDocumentsDirectory);
before you initialize the logging system:
  LoggerFactory.init(...)
════════════════════════════════════════════════════════════════════════════════
''';
  }

  static String getFileOrEmailAppenderErrorMessage() {
    return '''

════════════════════════════════════════════════════════════════════════════════
🚨 ANYLOGGER CONFIG ERROR: You're using a FILE or EMAIL appender on Flutter.
Flutter apps need proper path access to create log files.
════════════════════════════════════════════════════════════════════════════════
Add:
  path_provider: ^x.y.z // in pubspec.yaml
and call:
  LoggerFactory.setGetAppDocumentsDirectoryFnc(getApplicationDocumentsDirectory);
before you initialize the logging system:
  LoggerFactory.init(...)
════════════════════════════════════════════════════════════════════════════════
''';
  }
}
