# Any Logger

A powerful, flexible, and intuitive logging library for Dart and Flutter applications with automatic device/session
tracking and progressive complexity - from one-line setup to enterprise-grade configurations.

Logs can be sent to **console**, **file**, **JSON HTTP endpoints**, **email**, **MySQL databases**, or any custom
appender extension you create. Start with simple console logging and progressively add capabilities as your application
grows.

## ✨ Why Any Logger?

- **🚀 Zero Configuration** - Start logging with literally one line of code
- **📱 Flutter-First** - Built for mobile apps with proper app directory support
- **🔍 Automatic User Tracking** - Built-in anonymous device/session/version identification
- **📈 Progressive Complexity** - Simple for beginners, powerful for experts
- **⚡ Performance First** - Optimized with early exits, caching, and lazy evaluation
- **🎯 Production Ready** - Battle-tested with file rotation, batching, and error handling
- **🚨 Fail-Fast Design** - Clear errors instead of silent failures
- **📦 Zero Dependencies** - Core library has no dependencies

## 📦 Installation

```yaml
dependencies:
  any_logger: ^x.y.z // See "Installing"
```

That's it! No other dependencies needed to start logging.

## 🚀 Quick Start

### Flutter Apps

```dart
import 'package:any_logger/any_logger.dart';

void main() async {
  await LoggerFactory.initConsole();

  Logger.info("Flutter app started!");
  runApp(MyApp());
}
```

### Dart Console Apps

```dart
import 'package:any_logger/any_logger.dart';

void main() {
  Logger.info("I'm logging!"); // That's it! Auto-configures everything
}
```

No initialization needed for simple cases. The logger auto-configures on first use.

### One Line with Options

```dart
// Dart or Flutter
void main() {
  LoggerFactory.initSimpleConsole(level: Level.DEBUG);

  Logger.debug("Debug mode enabled");
  Logger.info("Application started");
  Logger.error("An error occurred");
}
```

## 📖 Configuration Examples

### Basic Console Logging

```dart
// Simple console with custom format
LoggerFactory.initConsole
(
format: '🚀 %l: %m',
level: Level.DEBUG,
);

// Professional console with file location
LoggerFactory.initProConsole(
level: Level.
DEBUG
,
);
// Output: [10:30:45][ROOT_LOGGER][INFO][main:42] User logged in [lib/main.dart(42:5)]
```

### File Logging

```dart
// Simple file logging
await LoggerFactory.initFile(
  filePattern: 'myapp',
  fileLevel: Level.DEBUG,
  consoleLevel: Level.INFO, // Optional console output
);
// Creates: myapp_2025-01-20.log

// Professional file setup
await LoggerFactory.initProFile(
  filePattern: 'myapp',
  fileLevel: Level.DEBUG,
  consoleLevel: Level.INFO,
);

// File logging with clearOnStartup option
await LoggerFactory.builder()
  .file(
    filePattern: 'myapp',
    level: Level.DEBUG,
    path: 'logs/',
    clearOnStartup: true, // Clear file contents on every app startup
  )
  .build();
```

### File Appender Configuration Options

| Option           | Type     | Default             | Description                                    |
|------------------|----------|---------------------|------------------------------------------------|
| `filePattern`    | String   | Required            | Base name for log files                        |
| `level`          | Level    | `Level.DEBUG`       | Minimum log level to write                     |
| `format`         | String   | `'%d [%l][%t] %c - %m [%f]'` | Log message format pattern       |
| `dateFormat`     | String   | `'yyyy-MM-dd HH:mm:ss.SSS'` | Timestamp format in log messages |
| `fileExtension`  | String   | `'log'`             | File extension for log files                   |
| `path`           | String   | `''`                | Directory path for log files                   |
| `rotationCycle`  | String   | `'DAY'`             | File rotation: `'NEVER'`, `'DAY'`, `'WEEK'`, `'MONTH'`, `'YEAR'` |
| `clearOnStartup` | bool     | `false`             | Clear file contents on every app startup      |

```

### Using Presets

```dart
// Development - verbose with full stack traces
await
LoggerFactory.initWithPreset
(
LoggerPresets.development);

// Production - optimized with essential info only
await LoggerFactory.initWithPreset(LoggerPresets.
production
);
```

### Builder Pattern

```dart
// Console and file logging
await
LoggerFactory.builder
().console
(
level: Level.INFO)
    .file(
filePattern: 'app',
level: Level.DEBUG,
path: 'logs/',
)
    .build();
```

### Using the AnyLogger Mixin

```dart
class PaymentService with AnyLogger {
  @override
  String get loggerName => 'PaymentService';

  void processPayment(String userId, double amount) {
    logInfo('Processing payment for $userId: \$$amount');

    if (isDebugEnabled) {
      logDebug('Payment details: ${_getExpensiveDetails()}');
    }

    logInfo('Payment successful');
  }
}
```

## 📝 Format Patterns

| Pattern | Description       | Example Output         |
|---------|-------------------|------------------------|
| `%d`    | Date/time         | `2025-01-20 10:30:45`  |
| `%l`    | Log level         | `INFO`                 |
| `%m`    | Message           | `User logged in`       |
| `%c`    | Class.method:line | `UserService.login:42` |
| `%f`    | File location     | `lib/user.dart(42:5)`  |
| `%i`    | Logger name       | `UserService`          |
| `%t`    | Tag               | `AUTH`                 |

### Example Formats

```dart
// Minimal
'%l: %m'
// Output: INFO: User logged in

// With timestamp
'%d [%l] %m'
// Output: 10:30:45 [INFO] User logged in

// With location
'[%l][%c] %m'
// Output: [INFO][UserService.login:42] User logged in

// More complete
'[%d][%did][%sid][%i][%l][%c] %m [%f]'
// Output: [11:50:43.399][lw8aqkjl][2xny54b4][ROOT_LOGGER][INFO][ServiceFactory.initializeCoreServices:326] Core services initialized successfully [package:my_app/service/service_factory.dart(326:7)]

```

## 🔀 Independent Side Loggers

Sometimes you need a separate logger that writes to its own file, independent of your main logging configuration. This is useful for audit logs, debug traces, or feature-specific logging.

### Creating a Side Logger

```dart
// Create a file appender for your specific needs
final specialAppender = await FileAppender.fromConfig({
  'filePattern': 'audit-logs',
  'level': 'INFO',
  'format': '%d [AUDIT] %m',
  'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
  'path': 'logs/audit/',
  'clearOnStartup': true, // Fresh logs on each app start
});

// Create an independent logger with only your appender
final auditLogger = Logger.defaultLogger([specialAppender], name: 'AuditLogger');

// Usage - completely separate from main logging
final mainLogger = LoggerFactory.getLogger('MyApp');
mainLogger.logInfo('Regular app logging'); // Goes to main appenders
auditLogger.logInfo('User action logged'); // Only goes to audit file
```

### Using FileAppenderBuilder for More Control

```dart
// More fluent API using the builder pattern
final specialAppender = await FileAppenderBuilder('debug-trace')
  .withLevel(Level.DEBUG)
  .withFormat('[%d][%c] %m')
  .withPath('logs/debug/')
  .withDailyRotation()
  .withClearOnStartup(true)
  .build();

final debugLogger = Logger.defaultLogger([specialAppender], name: 'DebugLogger');
```

### Real-World Example: Payment Processing

```dart
class PaymentService {
  late final Logger _mainLogger;
  late final Logger _auditLogger;
  
  Future<void> init() async {
    // Main application logging
    _mainLogger = LoggerFactory.getLogger('PaymentService');
    
    // Separate audit trail for compliance
    final auditAppender = await FileAppender.fromConfig({
      'filePattern': 'payment-audit',
      'level': 'INFO',
      'format': '[%d][%did][%sid] AUDIT: %m',
      'path': 'logs/audit/',
      'rotationCycle': 'MONTH', // Keep for longer periods
      'clearOnStartup': false,  // Never clear audit logs
    });
    
    _auditLogger = Logger.defaultLogger([auditAppender], name: 'PaymentAudit');
  }
  
  Future<void> processPayment(String userId, double amount) async {
    _mainLogger.logInfo('Processing payment for user $userId');
    _auditLogger.logInfo('PAYMENT_START user=$userId amount=$amount');
    
    try {
      // Process payment...
      _mainLogger.logInfo('Payment completed successfully');
      _auditLogger.logInfo('PAYMENT_SUCCESS user=$userId amount=$amount');
    } catch (e) {
      _mainLogger.logError('Payment failed: $e');
      _auditLogger.logInfo('PAYMENT_FAILED user=$userId amount=$amount error=$e');
      rethrow;
    }
  }
}
```

This approach gives you:
- **Complete separation** - Side logger doesn't interfere with main logging
- **Custom configuration** - Different formats, levels, and rotation for each purpose
- **Independent lifecycle** - Can flush, disable, or modify side loggers separately
- **Multiple side loggers** - Create as many specialized loggers as needed

## 🔍 Automatic User Tracking

Any Logger can automatically generate and persist anonymous IDs to help you understand user behavior without
compromising privacy:

- **Device ID** (`%did`) - Persists across app restarts, unique per device
- **Session ID** (`%sid`) - New for each app launch, tracks individual sessions
- **App Version** (`%app`) - Your application version for tracking deployments

### Basic Usage (Dart Console/Server)

```dart
// Just add IDs to your format - works automatically on Dart console/server
LoggerFactory.initConsole
(
format
:
'
[%did][%sid] %l: %m
'
,
);

// Output: [a3f5c8d2][e7b9f1a4] INFO: User clicked button
```

### Flutter Setup for Device/Session IDs

Flutter apps need additional setup for persistent device IDs:

```yaml
# Add to pubspec.yaml
dependencies:
  any_logger: ^x.y.z // See "Installing"
  path_provider: ^2.1.5  # Required for %did on Flutter
```

```dart
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect path_provider to AnyLogger (one line!)
  LoggerFactory.setGetAppDocumentsDirectoryFnc(getApplicationDocumentsDirectory);

  await LoggerFactory.initConsole(
    format: '[%app][%did][%sid] %l: %m',
  );

  LoggerFactory.setAppVersion('1.2.3');

  Logger.info('Device ID persists across app restarts!');
  // Output: [1.2.3][a3f5c8d2][e7b9f1a4] INFO: Device ID persists...

  runApp(MyApp());
}
```

### Alternative: Memory-Only IDs (No path_provider needed)

```dart
void main() async {
  // Use MemoryIdProvider when persistence isn't needed
  LoggerFactory.setIdProvider(MemoryIdProvider());

  await LoggerFactory.initConsole(
    format: '[%did][%sid] %l: %m', // IDs work but don't persist
  );

  runApp(MyApp());
}
```

This tracking helps you:

- Debug user-reported issues by asking for their logs
- Track which app versions have specific issues
- Understand user journeys without collecting personal data
- Maintain GDPR compliance with anonymous identifiers

## 🏷️ MDC - Mapped Diagnostic Context

Track context across all your logs - perfect for request tracking, user sessions, or feature flags:

```dart
// Set global context
LoggerFactory.setMdcValue
('userId
'
,
'
user-123
'
);LoggerFactory.setMdcValue('feature', 'new-checkout');

// Use in format with %X{key}
LoggerFactory.initConsole(
format: '[%X{userId}][%X{feature}] %l: %m',
);

// All logs now include context
Logger.info('Checkout started');
// Output: [user-123][new-checkout] INFO: Checkout started

// Clean up when done
LoggerFactory.removeMdcValue('userId');
```

### Request Tracking Example

```dart
class ApiServer {
  void handleRequest(Request request) {
    final requestId = Uuid().v4();

    // Set request context
    LoggerFactory.setMdcValue('requestId', requestId);
    LoggerFactory.setMdcValue('endpoint', request.uri.path);

    Logger.info('Request started');
    // Process request...
    Logger.info('Request completed');

    // Clean up
    LoggerFactory.clearMdc();
  }
}
```

## 🧩 Extension Packages

The core `any_logger` library is intentionally kept lightweight. Additional appenders are available through optional
extension packages:

### Available Extensions

| Package                                                                     | Description            | When to Use                                                            |
|-----------------------------------------------------------------------------|------------------------|------------------------------------------------------------------------|
| [**`any_logger_json_http`**](https://pub.dev/packages/any_logger_json_http) | JSON over HTTP logging | When sending logs to REST APIs, Logstash, centralized logging services |
| [**`any_logger_email`**](https://pub.dev/packages/any_logger_email)         | Email notifications    | For critical alerts, error notifications, and daily digests            |
| [**`any_logger_mysql`**](https://pub.dev/packages/any_logger_mysql)         | MySQL database logging | For structured, queryable log storage and audit trails                 |

### Installation

```yaml
dependencies:
  any_logger: ^x.y.z // See "Installing"
  any_logger_json_http: ^x.y.z  # Only if needed
  any_logger_email: ^x.y.z      # Only if needed
  any_logger_mysql: ^x.y.z      # Only if needed
```

### Usage Example

```dart
import 'package:any_logger/any_logger.dart';
import 'package:any_logger_json_http/any_logger_json_http.dart';

await
LoggerFactory.builder
().console
() // Core package
    .file
() // Core package
    .jsonHttp
( // Extension package
url: 'https://api.example.com/logs',
level: Level.ERROR,
bufferSize: 100,
)
    .build();
```

## ⚡ Performance Optimization

### Early Exit Pattern

```dart
// ❌ Bad - always computes expensive operation
logger.logDebug
(
expensiveComputation());

// ✅ Good - only computes if debug is enabled
if (logger.isDebugEnabled) {
logger.logDebug(expensiveComputation());
}

// ✅ Better - use supplier for lazy evaluation
logger.logDebugSupplier(() => expensiveComputation());
```

## 🔍 Troubleshooting

### Enable Self-Debugging

Having issues? Enable self-debugging to see what the logger is doing:

```dart
// See internal logger operations
LoggerFactory.builder
().console
(
level: Level.INFO)
    .withSelfDebug(Level.DEBUG
) // Shows platform detection, ID provider selection, etc.
.
build
(
);

// Output:
// [LoggerFactory.DEBUG] Platform: Dart | IDs: %did+%sid | Provider: FileIdProvider
// [LoggerFactory.DEBUG] Self-debugging enabled
// [LoggerFactory.DEBUG] Logger initialized with 1 appender
```

### Common Flutter Issues

#### "path_provider Not Configured for Device ID (%did)"

The logger will show a clear error message with instructions. Either:

- Add `path_provider` and configure it (see User Tracking section)
- Use `MemoryIdProvider` for non-persistent IDs
- Remove `%did` from your format

#### "No appender registered for type 'JSON_HTTP'"

Add and import the required extension package:

```yaml
dependencies:
  any_logger_json_http: ^x.y.z
```

and call the corresponding class to register the appender, like e.g.:

```dart
AnyLoggerJsonHttpExtension.register
();
```

#### "Permission denied" on Mobile

Use MemoryIdProvider instead of file-based storage:

```dart
LoggerFactory.setIdProvider
(
MemoryIdProvider
(
)
);
```

### Performance Tips

- If you don't use `%did` or `%sid`, the ID provider never runs
- Use `MemoryIdProvider` if persistence isn't needed
- Enable batching for network appenders (extension packages)
- Only import extension packages you actually use

## 🏆 Best Practices

1. **Start simple** - Use basic console logging, add features as needed
2. **Use self-debugging** when troubleshooting logger configuration
3. **Set appropriate log levels** - DEBUG for development, INFO/WARN for production
4. **Use named loggers** via the mixin for better organization
5. **Add tracking IDs** (`%did`/`%sid`) only when you need user journey tracking
6. **Use MDC** for request/transaction tracking
7. **Configure rotation** for file appenders to manage disk space
8. **Flush logs** before app termination: `await LoggerFactory.flushAll()`

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

This library is a fork of [Log4Dart2](https://github.com/Ephenodrom/Dart-Log-4-Dart-2) by Ephenodrom, enhanced with
modern features, performance optimizations, automatic ID tracking, and a simplified API.

## 📮 Support

- 📧 Email: hello@raoulsson.com
- 🐛 Issues: [GitHub Issues](https://github.com/raoulsson/any_logger/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/raoulsson/any_logger/discussions)

## 💚 Funding

- 🏅 https://github.com/sponsors/raoulsson
- 🪙 https://www.buymeacoffee.com/raoulsson

---

**Happy Logging! 🎉**