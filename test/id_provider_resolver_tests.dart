import 'dart:io';

import 'package:any_logger/any_logger.dart';
import 'package:test/test.dart';

void main() {
  group('IdProviderResolver', () {
    // Setup and teardown to reset test flags
    setUp(() {
      IdProviderResolver.isRunningAsUnitTest = true;
    });

    tearDown(() {
      IdProviderResolver.isRunningAsUnitTest = false;
      IdProviderResolver.unitTestIsFlutterResultValue = false;
    });

    group('analyzeRequirements', () {
      test('detects %did in appender format', () {
        final appenders = [
          MockAppender(format: '[%date] [%did] [%level] %message'),
        ];

        final result = IdProviderResolver.analyzeRequirements(appenders);

        expect(result.deviceIdNeeded, isTrue);
        expect(result.sessionIdNeeded, isFalse);
        expect(result.fileAppenderNeeded, isFalse);
      });

      test('detects %sid in appender format', () {
        final appenders = [
          MockAppender(format: '[%date] [%sid] [%level] %message'),
        ];

        final result = IdProviderResolver.analyzeRequirements(appenders);

        expect(result.deviceIdNeeded, isFalse);
        expect(result.sessionIdNeeded, isTrue);
        expect(result.fileAppenderNeeded, isFalse);
      });

      test('detects both %did and %sid', () {
        final appenders = [
          MockAppender(format: '[%date] [%did] [%sid] [%level] %message'),
        ];

        final result = IdProviderResolver.analyzeRequirements(appenders);

        expect(result.deviceIdNeeded, isTrue);
        expect(result.sessionIdNeeded, isTrue);
        expect(result.fileAppenderNeeded, isFalse);
      });

      test('detects FILE appender', () {
        final appenders = [
          MockAppender(format: '[%date] %message', type: 'FILE'),
        ];

        final result = IdProviderResolver.analyzeRequirements(appenders);

        expect(result.deviceIdNeeded, isFalse);
        expect(result.sessionIdNeeded, isFalse);
        expect(result.fileAppenderNeeded, isTrue);
      });

      test('detects EMAIL appender and sets deviceIdNeeded', () {
        final appenders = [
          MockAppender(format: '[%date] %message', type: 'EMAIL'),
        ];

        final result = IdProviderResolver.analyzeRequirements(appenders);

        expect(result.deviceIdNeeded, isTrue);
        expect(result.sessionIdNeeded, isFalse);
        expect(result.fileAppenderNeeded, isTrue);
      });

      test('handles multiple appenders with mixed requirements', () {
        final appenders = [
          MockAppender(format: '[%date] %message', type: 'CONSOLE'),
          MockAppender(format: '[%date] [%did] %message', type: 'FILE'),
          MockAppender(format: '[%date] [%sid] %message', type: 'EMAIL'),
        ];

        final result = IdProviderResolver.analyzeRequirements(appenders);

        expect(result.deviceIdNeeded, isTrue);
        expect(result.sessionIdNeeded, isTrue);
        expect(result.fileAppenderNeeded, isTrue);
      });

      test('analyzes Map<String, dynamic> config format', () {
        final config = {
          'appenders': [
            {'type': 'CONSOLE', 'format': '[%date] %message'},
            {'type': 'FILE', 'format': '[%date] [%did] %message'},
            {'type': 'EMAIL', 'format': '[%date] [%sid] %message'},
          ]
        };

        final result = IdProviderResolver.analyzeRequirements(config);

        expect(result.deviceIdNeeded, isTrue);
        expect(result.sessionIdNeeded, isTrue);
        expect(result.fileAppenderNeeded, isTrue);
      });
    });

    group('resolveProvider - Dart environment', () {
      setUp(() {
        IdProviderResolver.unitTestIsFlutterResultValue = false;
      });

      test('returns NullIdProvider when no IDs needed', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: false,
          sessionIdNeeded: false,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(provider, isA<NullIdProvider>());
      });

      test('returns FileIdProvider when device ID needed', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: true,
          sessionIdNeeded: false,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(provider, isA<FileIdProvider>());
      });

      test('returns FileIdProvider when session ID needed', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: false,
          sessionIdNeeded: true,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(provider, isA<FileIdProvider>());
      });

      test('returns FileIdProvider when both IDs needed', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: true,
          sessionIdNeeded: true,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(provider, isA<FileIdProvider>());
      });

      test('returns FileIdProvider when FILE appender used', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: false,
          sessionIdNeeded: false,
          fileAppenderNeeded: true,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(provider, isA<NullIdProvider>());
      });
    });

    group('resolveProvider - Flutter environment', () {
      setUp(() {
        IdProviderResolver.unitTestIsFlutterResultValue = true;
      });

      Future<Directory> mockGetAppDocumentsDirectory() async {
        return Directory('/mock/path');
      }

      test('throws when FILE appender used without path_provider', () {
        expect(
          () => IdProviderResolver.resolveProvider(
            deviceIdNeeded: false,
            sessionIdNeeded: false,
            fileAppenderNeeded: true,
            getAppDocumentsDirectoryFnc: null,
          ),
          throwsA(isA<StateError>().having((e) => e.message, 'message',
              contains('FILE or EMAIL appender on Flutter'))),
        );
      });

      test('throws when device ID needed without path_provider', () {
        expect(
          () => IdProviderResolver.resolveProvider(
            deviceIdNeeded: true,
            sessionIdNeeded: false,
            fileAppenderNeeded: false,
            getAppDocumentsDirectoryFnc: null,
          ),
          throwsA(isA<StateError>()
              .having((e) => e.message, 'message', contains('%did'))),
        );
      });

      test('returns FileIdProvider when device ID needed with path_provider',
          () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: true,
          sessionIdNeeded: false,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: mockGetAppDocumentsDirectory,
        );

        expect(provider, isA<FileIdProvider>());
      });

      test('returns MemoryIdProvider when only session ID needed', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: false,
          sessionIdNeeded: true,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(provider, isA<MemoryIdProvider>());
      });

      test('returns FileIdProvider when both IDs needed with path_provider',
          () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: true,
          sessionIdNeeded: true,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: mockGetAppDocumentsDirectory,
        );

        expect(provider, isA<FileIdProvider>());
      });

      test('works with FILE appender when path_provider provided', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: false,
          sessionIdNeeded: false,
          fileAppenderNeeded: true,
          getAppDocumentsDirectoryFnc: mockGetAppDocumentsDirectory,
        );

        expect(provider, isA<NullIdProvider>());
      });

      test('works with EMAIL appender when path_provider provided', () {
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: true, // EMAIL sets this
          sessionIdNeeded: false,
          fileAppenderNeeded: true, // EMAIL sets this
          getAppDocumentsDirectoryFnc: mockGetAppDocumentsDirectory,
        );

        expect(provider, isA<FileIdProvider>());
      });
    });

    group('getDebugSummary', () {
      Future<Directory> mockGetAppDocumentsDirectory() async {
        return Directory('/mock/path');
      }

      test('shows Dart platform with no features', () {
        IdProviderResolver.unitTestIsFlutterResultValue = false;

        final summary = IdProviderResolver.getDebugSummary(
          deviceIdNeeded: false,
          sessionIdNeeded: false,
          fileAppenderNeeded: false,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(summary, contains('Platform: Dart'));
        expect(summary, contains('Features: none'));
        expect(summary, contains('Provider: NullIdProvider'));
      });

      test('shows Flutter platform with all features', () {
        IdProviderResolver.unitTestIsFlutterResultValue = true;

        final summary = IdProviderResolver.getDebugSummary(
          deviceIdNeeded: true,
          sessionIdNeeded: true,
          fileAppenderNeeded: true,
          getAppDocumentsDirectoryFnc: mockGetAppDocumentsDirectory,
        );

        expect(summary, contains('Platform: Flutter'));
        expect(summary, contains('Features: %did+%sid+FILE+EMAIL'));
        expect(summary, contains('Provider: FileIdProvider'));
        expect(summary, contains('FILE: OK'));
      });

      test('shows error when Flutter needs path_provider', () {
        IdProviderResolver.unitTestIsFlutterResultValue = true;

        final summary = IdProviderResolver.getDebugSummary(
          deviceIdNeeded: true,
          sessionIdNeeded: false,
          fileAppenderNeeded: true,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(summary, contains('Platform: Flutter'));
        expect(summary, contains('Provider: ERROR-needs-path_provider'));
        expect(summary, contains('FILE: ERROR-needs-path_provider'));
      });
    });

    group('isFlutterApp', () {
      test('returns test value when running as unit test', () {
        IdProviderResolver.isRunningAsUnitTest = true;

        IdProviderResolver.unitTestIsFlutterResultValue = true;
        expect(IdProviderResolver.isFlutterApp(), isTrue);

        IdProviderResolver.unitTestIsFlutterResultValue = false;
        expect(IdProviderResolver.isFlutterApp(), isFalse);
      });

      test('uses environment check when not in test mode', () {
        IdProviderResolver.isRunningAsUnitTest = false;

        // This will return false in pure Dart test environment
        expect(IdProviderResolver.isFlutterApp(), isFalse);
      });
    });

    group('Integration scenarios', () {
      test('CONSOLE only appender needs no special setup', () {
        IdProviderResolver.unitTestIsFlutterResultValue = false;

        final appenders = [
          MockAppender(format: '[%date] [%level] %message', type: 'CONSOLE'),
        ];

        final requirements = IdProviderResolver.analyzeRequirements(appenders);
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: requirements.deviceIdNeeded,
          sessionIdNeeded: requirements.sessionIdNeeded,
          fileAppenderNeeded: requirements.fileAppenderNeeded,
          getAppDocumentsDirectoryFnc: null,
        );

        expect(provider, isA<NullIdProvider>());
      });

      test('FILE + EMAIL in Flutter requires path_provider', () {
        IdProviderResolver.unitTestIsFlutterResultValue = true;

        final appenders = [
          MockAppender(format: '[%date] [%did] %message', type: 'FILE'),
          MockAppender(format: '[%date] %message', type: 'EMAIL'),
        ];

        final requirements = IdProviderResolver.analyzeRequirements(appenders);

        // Should throw without path_provider
        expect(
          () => IdProviderResolver.resolveProvider(
            deviceIdNeeded: requirements.deviceIdNeeded,
            sessionIdNeeded: requirements.sessionIdNeeded,
            fileAppenderNeeded: requirements.fileAppenderNeeded,
            getAppDocumentsDirectoryFnc: null,
          ),
          throwsStateError,
        );

        // Should work with path_provider
        final provider = IdProviderResolver.resolveProvider(
          deviceIdNeeded: requirements.deviceIdNeeded,
          sessionIdNeeded: requirements.sessionIdNeeded,
          fileAppenderNeeded: requirements.fileAppenderNeeded,
          getAppDocumentsDirectoryFnc: () async => Directory('/test'),
        );

        expect(provider, isA<FileIdProvider>());
      });
    });
  });
}

// Mock appender for testing
class MockAppender extends Appender {
  @override
  final String format;
  final String type;

  MockAppender({this.format = '', this.type = 'CONSOLE'});

  @override
  void append(LogRecord logRecord) {}

  @override
  Appender createDeepCopy() => MockAppender(format: format, type: type);

  @override
  Future<void> dispose() async {}

  @override
  Future<void> flush() async {}

  @override
  Map<String, dynamic> getConfig() => {'format': format, 'type': type};

  @override
  String getShortConfigDesc() => 'Mock($type)';

  @override
  String getType() => type;
}
