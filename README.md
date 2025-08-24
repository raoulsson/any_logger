# Any Logger

A powerful, flexible, and intuitive logging library for Dart and Flutter applications with automatic device/session tracking and progressive complexity - from one-line setup to enterprise-grade configurations.

**Flutter-first design** with proper mobile app support, persistent device IDs, and clear error messages.

## ✨ Why Any Logger?

- **🚀 Zero Configuration** - Start logging with literally one line of code
- **📱 Flutter-First** - Built for mobile apps with proper app directory support
- **🔍 Automatic User Tracking** - Built-in anonymous device/session/version identification
- **📈 Progressive Complexity** - Simple for beginners, powerful for experts
- **⚡ Performance First** - Optimized with early exits, caching, and lazy evaluation
- **🎯 Production Ready** - Battle-tested with file rotation, batching, and error handling
- **🚨 Fail-Fast Design** - Clear errors instead of silent failures
- **📦 Minimal Dependencies** - Core library has only one dependency (`crypto`)

## 📦 Installation

### Core Package (Console & File logging)
```yaml
dependencies:
  any_logger: ^1.0.0
  path_provider: ^2.1.5  # Required for Flutter apps using %did or %sid
```

### Extension Packages (Add only what you need)
```yaml
dependencies:
  # For JSON HTTP logging
  any_logger_json_http: ^1.0.0
  
  # For Email logging
  any_logger_email: ^1.0.0
  
  # For MySQL logging
  any_logger_mysql: ^1.0.0
```

## 🚀 Quick Start

### Flutter Apps

```dart
import 'package:any_logger/any_logger.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Required for Flutter if using %did or %sid
  AnyLoggerFileIdProvider.getAppDocumentsDirectory = getApplicationDocumentsDirectory;
  
  await LoggerFactory.initConsole(
    format: '[%did][%sid] %l: %m',
  );
  
  Logger.info("Flutter app started!");
  runApp(MyApp());
}
```

### What Happens Without path_provider?

If you forget to add `path_provider` or set `getAppDocumentsDirectory`, the logger will **fail fast** with clear instructions:

```
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
```

## 🔧 ID Provider Configuration for Flutter

Any Logger automatically detects Flutter apps and requires proper setup for device/session tracking:

### Flutter Mobile Setup (Required for %did/%sid)
```dart
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connect path_provider to AnyLogger (one line!)
  FileIdProvider.getAppDocumentsDirectory = getApplicationDocumentsDirectory;
  
  await LoggerFactory.init({
    'appenders': [{
      'type': 'CONSOLE',
      'format': '[%app][%did][%sid] %l: %m',
      'level': 'INFO',
    }]
  }, appVersion: '1.0.0');
  
  Logger.info('Device ID persists across app restarts!');
  runApp(MyApp());
}
```

### Flutter Without Device/Session IDs (Simplest)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // No path_provider needed if you don't use %did or %sid
  await LoggerFactory.initConsole(
    format: '%l: %m',  // No IDs = no path_provider needed
  );
  
  runApp(MyApp());
}
```

### Flutter Web / No Persistence Needed
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use MemoryIdProvider for web or when persistence isn't needed
  LoggerFactory.setIdProvider(MemoryIdProvider());
  
  await LoggerFactory.initConsole(
    format: '[%did][%sid] %l: %m',  // IDs work but don't persist
  );
  
  runApp(MyApp());
}
```

### Dart Console Apps / Servers

```dart
import 'package:any_logger/any_logger.dart';

void main() {
  Logger.info("I'm logging!");  // That's it! Auto-configures everything
}
```

Yes, really! No initialization needed for simple cases. The logger auto-configures on first use.

### One Line with Options

```dart
void main() {
  LoggerFactory.initSimpleConsole(level: Level.DEBUG);
  
  Logger.debug("Debug mode enabled");
  Logger.info("Application started");
  Logger.error("An error occurred");
}
```

## 🔍 Automatic Anonymous User Tracking

Any Logger automatically generates and persists anonymous IDs to help you understand user behavior without compromising privacy:

- **Device ID** (`%did`) - Persists across app restarts, unique per device
- **Session ID** (`%sid`) - New for each app launch, tracks individual sessions
- **App Version** (`%app`) - Your application version for tracking deployments

```dart
// Enable tracking in your format
LoggerFactory.initConsole(
  format: '[%app][%did][%sid] %l: %m',
);

// Set app version
LoggerFactory.setAppVersion('1.2.3');

// Output: [1.2.3][a3f5c8d2][e7b9f1a4] INFO: User clicked button
// Now you can track what users do across sessions and app versions!
```

This helps you:
- Debug user-reported issues by asking for their logs
- Track which app versions have specific issues
- Understand user journeys without collecting personal data
- Track session-specific problems
- Maintain GDPR compliance with anonymous identifiers

## 📖 Progressive Usage Examples

### Level 1: Using Built-in Presets

```dart
// Development - verbose with full stack traces
await LoggerFactory.initWithPreset(LoggerPresets.development);

// Production - optimized with essential info only
await LoggerFactory.initWithPreset(LoggerPresets.production);

// Professional - includes device/session tracking
await LoggerFactory.initWithPreset(LoggerPresets.developmentPro);

// Production with app version tracking
await LoggerFactory.initWithPreset(
  LoggerPresets.productionWithApp,
  appVersion: '1.2.3',
);

// Mobile optimized with version
await LoggerFactory.initWithPreset(
  LoggerPresets.mobileProduction,
  appVersion: '1.2.3',
);
```

### Level 2: Simple Configurations

```dart
// Console with custom format
LoggerFactory.initConsole(
  format: '🚀 %l: %m',
  level: Level.DEBUG,
);

// Professional console with file location
LoggerFactory.initProConsole(
  level: Level.DEBUG,
  includeIds: true,  // Enable device/session tracking
);

// File logging with app version
await LoggerFactory.initFile(
  filePattern: 'myapp',
  fileLevel: Level.DEBUG,
  consoleLevel: Level.INFO,  // Optional console output
  appVersion: '1.2.3',  // Include app version in logs
);

// Professional file with all metadata
await LoggerFactory.initProFileWithApp(
  filePattern: 'myapp',
  appVersion: '1.2.3',
  fileLevel: Level.DEBUG,
  consoleLevel: Level.INFO,
);
```

### Level 3: Fluent Builder Pattern

```dart
// Simple builder - Core package only
await LoggerFactory.builder()
    .console(level: Level.INFO)
    .file(
      filePattern: 'app',
      level: Level.DEBUG,
      path: 'logs/',
    )
    .build();

// With app version tracking - Core package only
await LoggerFactory.builder()
    .console(
      format: '[%app][%sid][%l] %m',
    )
    .file(
      filePattern: 'app',
      path: 'logs/',
    )
    .withAppVersion('1.2.3')
    .build();
```

### Level 4: With Extension Packages

```dart
// First, add the required packages to pubspec.yaml:
// dependencies:
//   any_logger_json_http: ^1.0.0
//   any_logger_email: ^1.0.0

import 'package:any_logger/any_logger.dart';
import 'package:any_logger_json_http/any_logger_json_http.dart';
import 'package:any_logger_email/any_logger_email.dart';

// Advanced multi-appender setup with extensions
await LoggerFactory.builder()
    .console(
      level: Level.WARN,
      format: '[%d][%app][%did][%sid][%l] %m',
    )
    .file(
      filePattern: 'app',
      level: Level.DEBUG,
      path: 'logs/',
    )
    .jsonHttp(  // Requires any_logger_json_http package
      url: 'https://logs.example.com',
      level: Level.ERROR,
      bufferSize: 100,
    )
    .email(  // Requires any_logger_email package
      host: 'smtp.gmail.com',
      to: ['admin@example.com'],
      level: Level.FATAL,
    )
    .withAppVersion('1.2.3')
    .withMdcValue('environment', 'production')
    .build();
```

## 🏷️ MDC - Mapped Diagnostic Context

Track context across all your logs - perfect for request tracking, user sessions, or feature flags:

```dart
// Set global context
LoggerFactory.setMdcValue('userId', 'user-123');
LoggerFactory.setMdcValue('feature', 'new-checkout');

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

## 🎨 Using the AnyLogger Mixin

Add logging superpowers to any class:

```dart
class PaymentService with AnyLogger {
  @override
  String get loggerName => 'PaymentService';
  
  Future<void> processPayment(String userId, double amount) async {
    logInfo('Processing payment for $userId: \$$amount');
    
    try {
      // Only compute expensive debug info if needed
      if (isDebugEnabled) {
        logDebug('Payment details: ${_getDetailedInfo()}');
      }
      
      await _chargeCard(amount);
      logInfo('Payment successful');
      
    } catch (e, stack) {
      logError('Payment failed', exception: e, stackTrace: stack);
      rethrow;
    }
  }
}
```

## 🔧 ID Provider Configuration for Flutter

Any Logger needs proper setup for device/session tracking on Flutter:

### Flutter Mobile Setup (Recommended)
```dart
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure for Flutter - REQUIRED if using %did or %sid
  AnyLoggerFileIdProvider.getAppDocumentsDirectory = getApplicationDocumentsDirectory;
  
  await LoggerFactory.init({
    'appenders': [{
      'type': 'CONSOLE',
      'format': '[%app][%did][%sid] %l: %m',
      'level': 'INFO',
    }]
  }, appVersion: '1.0.0');
  
  Logger.info('Device ID persists across app restarts!');
  runApp(MyApp());
}
```

### Flutter Web / No Persistence Needed
```dart
void main() {
  // Use MemoryIdProvider for web or when persistence isn't needed
  LoggerFactory.setIdProvider(MemoryIdProvider());
  
  LoggerFactory.initConsole(
    format: '[%did][%sid] %l: %m',
  );
  
  runApp(MyApp());
}
```

### No IDs Needed (Simplest)
```dart
void main() {
  // If you don't use %did or %sid, no setup needed!
  LoggerFactory.initConsole(
    format: '%l: %m',  // No IDs = works everywhere
  );
  
  runApp(MyApp());
}
```

## 📝 Format Patterns

| Pattern | Description | Example Output |
|---------|-------------|----------------|
| `%d` | Date/time | `2025-01-20 10:30:45` |
| `%did` | Device ID (anonymous) | `a3f5c8d2` |
| `%sid` | Session ID | `e7b9f1a4` |
| `%app` | App version | `1.2.3` |
| `%l` | Log level | `INFO` |
| `%m` | Message | `User logged in` |
| `%c` | Class.method:line | `UserService.login:42` |
| `%f` | File location | `lib/user.dart(42:5)` |
| `%i` | Logger name | `UserService` |
| `%t` | Tag | `AUTH` |
| `%X{key}` | MDC value | `production` |

### Example Formats

```dart
// Minimal
'%l: %m'
// Output: INFO: User logged in

// With timestamp
'%d [%l] %m'
// Output: 10:30:45 [INFO] User logged in

// Production with tracking
'[%did][%sid][%l][%c] %m'
// Output: [a3f5c8d2][e7b9f1a4][INFO][UserService.login:42] User logged in

// With app version
'[%app][%sid][%l] %m'
// Output: [1.2.3][e7b9f1a4][INFO] User logged in

// Full debug format
'[%d][%app][%did][%sid][%X{env}][%i][%l][%c] %m [%f]'
// Output: [10:30:45][1.2.3][a3f5c8d2][e7b9f1a4][prod][UserService][INFO][login:42] User logged in [lib/user.dart(42:5)]
```

## 🧩 Extension Packages

The core `any_logger` library is intentionally kept lightweight with minimal dependencies (only `crypto`). Additional appenders for network and database logging are provided through separate, optional extension packages.

**Core package includes:**
- ✅ Console appender (stdout and developer tools)
- ✅ File appender with rotation

**Extension packages provide:**
- 📦 JSON HTTP appender (requires `any_logger_json_http`)
- 📦 Email appender (requires `any_logger_email`)
- 📦 MySQL appender (requires `any_logger_mysql`)

You only need to add the packages for the appenders you actually use:

| Package | Description | When to Use |
|---------|-------------|-------------|
| **`any_logger`** | Core library with Console & File appenders | Always required |
| **`any_logger_json_http`** | JSON over HTTP logging | When sending logs to REST APIs, Logstash, etc. |
| **`any_logger_email`** | Email notifications | For critical alerts and error notifications |
| **`any_logger_mysql`** | MySQL database logging | For structured, queryable log storage |

### Using Extension Packages

```dart
// 1. Add to pubspec.yaml
dependencies:
  any_logger: ^1.0.0
  any_logger_json_http: ^1.0.0  # Only if needed
  any_logger_email: ^1.0.0      # Only if needed
  any_logger_mysql: ^1.0.0      # Only if needed

// 2. Import the extensions you need
import 'package:any_logger/any_logger.dart';
import 'package:any_logger_json_http/any_logger_json_http.dart';
import 'package:any_logger_email/any_logger_email.dart';

// 3. Use them in your configuration
await LoggerFactory.builder()
    .console()  // Core package
    .file()     // Core package
    .jsonHttp(  // Extension package
      url: 'https://api.example.com/logs',
    )
    .email(     // Extension package
      host: 'smtp.gmail.com',
      to: ['admin@example.com'],
    )
    .build();
```

## 🎯 Appenders

### Core Appenders (Always Available)

#### Console Appender
```dart
LoggerFactory.builder()
    .console(
      level: Level.DEBUG,
      format: '%d [%l] %m',
      devtools: true,  // Use Flutter DevTools output
    )
    .build();
```

#### File Appender with Rotation
```dart
await LoggerFactory.builder()
    .file(
      filePattern: 'myapp',
      path: 'logs/',
      rotationCycle: 'DAY',  // DAY, WEEK, MONTH, YEAR, NEVER
      level: Level.DEBUG,
    )
    .build();
// Creates: logs/myapp_2025-01-20.log
```

### Extension Appenders (Require Additional Packages)

#### JSON HTTP Appender
**Requires:** `any_logger_json_http: ^1.0.0`

```dart
import 'package:any_logger_json_http/any_logger_json_http.dart';

await LoggerFactory.builder()
    .jsonHttp(
      url: 'https://api.example.com/logs',
      username: 'apiuser',
      password: 'apipass',
      bufferSize: 100,  // Batch 100 logs
      flushIntervalSeconds: 60,  // Or flush every minute
      enableCompression: true,  // Gzip compression
    )
    .build();
```

#### Email Appender
**Requires:** `any_logger_email: ^1.0.0`

```dart
import 'package:any_logger_email/any_logger_email.dart';

await LoggerFactory.builder()
    .email(
      host: 'smtp.gmail.com',
      port: 587,
      user: 'alerts@example.com',
      password: 'password',
      to: ['admin@example.com'],
      minLevelForImmediate: Level.ERROR,  // Send errors immediately
      batchSize: 10,  // Batch info/debug logs
    )
    .build();
```

#### MySQL Appender
**Requires:** `any_logger_mysql: ^1.0.0`

```dart
import 'package:any_logger_mysql/any_logger_mysql.dart';

await LoggerFactory.builder()
    .mysql(
      host: 'localhost',
      database: 'logs',
      user: 'logger',
      password: 'password',
      table: 'app_logs',
      batchSize: 50,
    )
    .build();
```

## ⚡ Performance Optimization

### Early Exit Pattern
```dart
// ❌ Bad - always computes expensive operation
logger.logDebug(expensiveComputation());

// ✅ Good - only computes if debug is enabled
if (logger.isDebugEnabled) {
  logger.logDebug(expensiveComputation());
}

// ✅ Better - use supplier for lazy evaluation
logger.logDebugSupplier(() => expensiveComputation());
```

### Batch Processing
```dart
// Configure batching for network appenders (requires extension package)
import 'package:any_logger_json_http/any_logger_json_http.dart';

final logger = LoggerFactory.builder()
    .jsonHttp(
      url: 'https://logs.example.com',
      bufferSize: 100,  // Send after 100 logs
      flushIntervalSeconds: 30,  // Or after 30 seconds
    )
    .build();

// Manual flush when needed (e.g., before app terminates)
await LoggerFactory.flushAll();
```

## 🔍 Self-Debugging

Having issues with the logger itself? Enable self-debugging:

```dart
LoggerFactory.builder()
    .console(level: Level.INFO)
    .withSelfDebug(Level.DEBUG)  // See what the logger is doing
    .build();
```

## 📊 Real-World Examples

### Flutter App with Crash Reporting
```dart
// Add to pubspec.yaml:
// dependencies:
//   any_logger: ^5.2.0
//   any_logger_json_http: ^1.0.0

import 'package:any_logger/any_logger.dart';
import 'package:any_logger_json_http/any_logger_json_http.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure path provider for Flutter
  AnyLoggerFileIdProvider.getAppDocumentsDirectory = getApplicationDocumentsDirectory;
  
  // Setup logging with automatic tracking
  await LoggerFactory.builder()
      .console(
        level: kDebugMode ? Level.DEBUG : Level.INFO,
        format: '[%app][%sid][%l] %m',
      )
      .file(
        filePattern: 'app',
        level: Level.DEBUG,
        path: (await getApplicationDocumentsDirectory()).path,
        format: '[%d][%app][%did][%sid][%l][%c] %m [%f]',
      )
      .jsonHttp(  // Requires extension package
        url: 'https://logs.myapp.com',
        level: Level.ERROR,  // Only send errors to server
      )
      .withAppVersion('1.2.3')
      .withMdcValue('platform', Platform.operatingSystem)
      .build();
  
  // Catch Flutter errors
  FlutterError.onError = (details) {
    Logger.fatal('Flutter error', exception: details.exception, stackTrace: details.stack);
  };
  
  runApp(MyApp());
}
```

### Backend Service with Request Tracking
```dart
class ApiServer {
  void handleRequest(Request request) {
    final requestId = Uuid().v4();
    
    // Set request context
    LoggerFactory.setMdcValue('requestId', requestId);
    LoggerFactory.setMdcValue('endpoint', request.uri.path);
    LoggerFactory.setMdcValue('method', request.method);
    
    try {
      Logger.info('Request started');
      
      // Process request...
      
      Logger.info('Request completed');
    } finally {
      // Clean up context
      LoggerFactory.clearMdc();
    }
  }
}
```

## 🏆 Best Practices

1. **Always set app version** with `%app` to track issues across releases
2. **Use device/session IDs** (`%did`/`%sid`) for anonymous user tracking and debugging
3. **Set appropriate log levels** - DEBUG for development, INFO/WARN for production
4. **Use MDC** for adding context to all logs (user ID, request ID, etc.)
5. **Enable batching** for network/database appenders to reduce overhead (extension packages)
6. **Use early exit checks** or suppliers for expensive debug logging
7. **Configure rotation** for file appenders to manage disk space
8. **Set up immediate alerts** for ERROR/FATAL with email appender (extension package)
9. **Use named loggers** for better organization in large apps
10. **Enable self-debugging** when troubleshooting logger issues
11. **Flush logs** before app termination to avoid data loss
12. **Only add extension packages you actually use** to minimize dependencies

## 🔄 Dynamic Configuration

Modify logger behavior at runtime:

```dart
final logger = LoggerFactory.getRootLogger();

// Change log level dynamically
logger.setLevelAll(Level.WARN);

// Change format
logger.setFormatAll('[%sid] %l: %m');

// Enable/disable specific appenders by type
LoggerFactory.disableAppender('FILE');
LoggerFactory.enableAppender('CONSOLE');

// Reset to initial configuration
logger.resetFormatToInitialConfig();
```

## 🔍 Troubleshooting

### Common Flutter Issues

#### "FileIdProvider failed to persist device ID"
**Solution:** Configure path_provider:
```dart
AnyLoggerFileIdProvider.getAppDocumentsDirectory = getApplicationDocumentsDirectory;
```

#### "Permission denied" on Mobile
**Solution:** Add storage permissions or use MemoryIdProvider:
```dart
LoggerFactory.setIdProvider(MemoryIdProvider());
```

#### "Cannot use sync init with Flutter"
**Solution:** Use async initialization:
```dart
await LoggerFactory.init(...);  // Not initSync()
```

#### "No appender registered for type 'JSON_HTTP'"
**Solution:** Add and import the required extension package:
```yaml
dependencies:
  any_logger_json_http: ^1.0.0
```
```dart
import 'package:any_logger_json_http/any_logger_json_http.dart';
```

### Performance Tips

- If you don't use `%did` or `%sid`, the ID provider never runs
- Use `MemoryIdProvider` for web apps
- Enable batching for network appenders (extension packages)
- Only import extension packages you actually use

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

This library is a fork of [Log4Dart2](https://github.com/Ephenodrom/Dart-Log-4-Dart-2) by Ephenodrom, enhanced with modern features, performance optimizations, automatic ID tracking, and a simplified API.

## 📮 Support

- 📧 Email: hello@raoulsson.com
- 🐛 Issues: [GitHub Issues](https://github.com/raoulsson/any_logger/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/raoulsson/any_logger/discussions)

## 👏 Funding

- 🏅 https://github.com/sponsors/raoulsson
- 🪙 https://www.buymeacoffee.com/raoulsson

---

**Happy Logging! 🎉**