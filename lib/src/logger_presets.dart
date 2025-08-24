// ============================================================
// PRESET CONFIGURATIONS - PRODUCTION-READY PATTERNS
// ============================================================

import '../any_logger_lib.dart';

/// Preset configurations for common use cases with device and session tracking
class LoggerPresets {
  // ============================================================
  // BASIC PRESETS - Simple setups for quick starts
  // ============================================================

  /// Minimal console logging - just the essentials
  static const minimal = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '%l: %m',
        'level': 'INFO',
        'dateFormat': 'HH:mm:ss',
      }
    ],
  };

  /// Simple console with timestamp
  static const simple = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '%d %l: %m',
        'level': 'INFO',
        'dateFormat': 'HH:mm:ss.SSS',
      }
    ],
  };

  // ============================================================
  // DEVELOPMENT PRESETS - Maximum visibility for debugging
  // ============================================================

  /// Development with full stack trace info
  static const development = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '%d [%l][%c] %m [%f]',
        'level': 'DEBUG',
        'dateFormat': 'HH:mm:ss.SSS',
      }
    ],
  };

  /// Development with device/session tracking
  static const developmentPro = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%did][%sid][%i][%l][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'HH:mm:ss.SSS',
      }
    ],
  };

  /// Development with app version and full tracking
  static const developmentWithApp = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%app][%did][%sid][%i][%l][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'HH:mm:ss.SSS',
      }
    ],
  };

  /// Development with file output for persistent debugging
  static const developmentWithFile = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '%d [%l][%c] %m',
        'level': 'DEBUG',
        'dateFormat': 'HH:mm:ss.SSS',
      },
      {
        'type': 'FILE',
        'format': '[%d][%did][%sid][%i][%l][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'debug',
        'path': 'logs/',
        'rotationCycle': 'DAY',
      }
    ],
  };

  // ============================================================
  // PRODUCTION PRESETS - Optimized for production environments
  // ============================================================

  /// Basic production - clean console output
  static const production = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '%d [%l] %m',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss',
      }
    ],
  };

  /// Production with session tracking for user journey analysis
  static const productionWithTracking = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%sid][%l] %m',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss',
      }
    ],
  };

  /// Production with full tracking and file backup
  static const productionPro = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%sid][%l] %m',
        'level': 'DEBUG', // Console only shows warnings and errors
        'dateFormat': 'HH:mm:ss',
      },
      {
        'type': 'FILE',
        'format': '[%d][%did][%sid][%i][%l][%c] %m [%f]',
        'level': 'INFO', // File captures everything INFO and above
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'app',
        'path': 'logs/',
        'rotationCycle': 'DAY',
      }
    ],
  };

  /// Production with app version tracking
  static const productionWithApp = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%app][%sid][%l] %m',
        'level': 'INFO',
        'dateFormat': 'HH:mm:ss',
      },
      {
        'type': 'FILE',
        'format': '[%d][%app][%did][%sid][%i][%l][%c] %m [%f]',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'app',
        'path': 'logs/',
        'rotationCycle': 'DAY',
      }
    ],
  };

  // ============================================================
  // MOBILE APP PRESETS - Optimized for mobile applications
  // ============================================================

  /// Mobile app development
  static const mobileDevelopment = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%did][%sid][%l][%c] %m',
        'level': 'DEBUG',
        'dateFormat': 'HH:mm:ss.SSS',
        //'mode': 'devtools',  // Use devtools mode for Flutter
      }
    ],
  };

  /// Mobile app production with crash reporting
  static const mobileProduction = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%sid][%l] %m',
        'level': 'WARN',
        'dateFormat': 'HH:mm:ss',
      },
      {
        'type': 'FILE',
        'format': '[%d][%app][%did][%sid][%l][%c] %m [%f]',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'app',
        'path': 'logs/',
        'rotationCycle': 'WEEK', // Weekly rotation for mobile
      }
    ],
  };

  /// Mobile app with remote logging for crash analytics
  static Map<String, dynamic> mobileCrashReporting({
    required String crashReportUrl,
    String? apiKey,
  }) {
    return {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[%l] %m',
          'level': 'ERROR',
          'dateFormat': 'HH:mm:ss',
        },
        {
          'type': 'FILE',
          'format': '[%d][%app][%did][%sid][%l] %m [%f]',
          'level': 'WARN',
          'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
          'filePattern': 'crash',
          'path': 'logs/',
          'rotationCycle': 'DAY',
        },
        {
          'type': 'JSON_HTTP',
          'url': crashReportUrl,
          'headers': apiKey != null ? ['X-API-Key:$apiKey'] : [],
          'level': 'ERROR',
          'bufferSize': 10,
          'flushIntervalSeconds': 30, // Send crashes quickly
          'enableCompression': true,
        }
      ],
    };
  }

  // ============================================================
  // WEB APP PRESETS - Browser and server-side web applications
  // ============================================================

  /// Web app development with browser console
  static const webDevelopment = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%sid][%l][%c] %m',
        'level': 'DEBUG',
        'dateFormat': 'HH:mm:ss.SSS',
      }
    ],
  };

  /// Web app production with session tracking
  static const webProduction = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%sid][%X{userId}][%l] %m',
        'level': 'INFO',
        'dateFormat': 'HH:mm:ss',
      }
    ],
  };

  /// Web app with analytics tracking
  static Map<String, dynamic> webWithAnalytics({
    required String analyticsUrl,
    String? username,
    String? password,
  }) {
    return {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[%sid][%l] %m',
          'level': 'WARN',
          'dateFormat': 'HH:mm:ss',
        },
        {
          'type': 'JSON_HTTP',
          'url': analyticsUrl,
          'username': username,
          'password': password,
          'level': 'INFO',
          'bufferSize': 100,
          'flushIntervalSeconds': 60,
          'enableCompression': true,
        }
      ],
    };
  }

  // ============================================================
  // MICROSERVICE PRESETS - Distributed system logging
  // ============================================================

  /// Microservice with correlation IDs
  static const microservice = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%X{service}][%X{traceId}][%X{spanId}][%l] %m',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', // ISO 8601
      }
    ],
  };

  /// Microservice with structured logging
  static const microserviceStructured = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '{"time":"%d","service":"%X{service}","trace":"%X{traceId}","level":"%l","msg":"%m"}',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',
      }
    ],
  };

  /// Microservice with centralized logging
  static Map<String, dynamic> microserviceWithCentralLogging({
    required String logAggregatorUrl,
    required String serviceName,
    String? environment,
  }) {
    return {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[%X{traceId}][%l] %m',
          'level': 'WARN',
          'dateFormat': 'HH:mm:ss.SSS',
        },
        {
          'type': 'JSON_HTTP',
          'url': logAggregatorUrl,
          'headers': [
            'X-Service-Name:$serviceName',
            if (environment != null) 'X-Environment:$environment',
          ],
          'level': 'INFO',
          'bufferSize': 200,
          'flushIntervalSeconds': 10,
          'enableCompression': true,
        }
      ],
    };
  }

  // ============================================================
  // TESTING PRESETS - For automated testing and CI/CD
  // ============================================================

  /// Testing - minimal output for unit tests
  static const testing = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%l] %m',
        'level': 'ERROR', // Only show errors in tests
        'dateFormat': 'HH:mm:ss',
      }
    ],
  };

  /// Testing with verbose output for debugging test failures
  static const testingVerbose = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[TEST][%d][%l][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'HH:mm:ss.SSS',
      }
    ],
  };

  /// Integration testing with file output
  static const integrationTesting = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%l] %m',
        'level': 'INFO',
        'dateFormat': 'HH:mm:ss',
      },
      {
        'type': 'FILE',
        'format': '[%d][%did][%sid][%l][%c] %m [%f]',
        'level': 'DEBUG',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'test',
        'path': 'test_logs/',
        'rotationCycle': 'NEVER',
      }
    ],
  };

  // ============================================================
  // SPECIALIZED PRESETS - Domain-specific configurations
  // ============================================================

  /// Database operations logging
  static const database = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[DB][%d][%X{query-id}][%l] %m',
        'level': 'DEBUG',
        'dateFormat': 'HH:mm:ss.SSS',
      },
      {
        'type': 'FILE',
        'format': '[%d][%X{query-id}][%X{user}][%l] %m - Query: %X{sql}',
        'level': 'TRACE',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'database',
        'path': 'logs/db/',
        'rotationCycle': 'DAY',
      }
    ],
  };

  /// API gateway logging
  static const apiGateway = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%X{request-id}][%X{method}][%X{path}][%l] %m - %X{status}',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss',
      }
    ],
  };

  /// Audit logging for compliance
  static const audit = {
    'appenders': [
      {
        'type': 'FILE',
        'format': '[AUDIT][%d][%did][%sid][%X{userId}][%X{action}][%l] %m [%f]',
        'level': 'INFO',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'audit',
        'path': 'audit_logs/',
        'rotationCycle': 'MONTH', // Keep audit logs longer
      },
      {
        'type': 'CONSOLE',
        'format': '[AUDIT][%X{userId}][%X{action}] %m',
        'level': 'WARN',
        'dateFormat': 'HH:mm:ss',
      }
    ],
  };

  /// Performance monitoring
  static const performance = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[PERF][%d][%X{operation}][%X{duration}ms][%l] %m',
        'level': 'INFO',
        'dateFormat': 'HH:mm:ss.SSS',
      },
      {
        'type': 'FILE',
        'format': '[%d][%did][%sid][%X{operation}][%X{duration}][%l] %m [%f]',
        'level': 'DEBUG',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'performance',
        'path': 'logs/perf/',
        'rotationCycle': 'DAY',
      }
    ],
  };

  // ============================================================
  // ENVIRONMENT-BASED PRESETS - Different configs per environment
  // ============================================================

  /// Get preset based on environment
  static Map<String, dynamic> forEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'local':
      case 'dev':
      case 'development':
        return developmentPro;
      case 'test':
      case 'testing':
        return testing;
      case 'staging':
      case 'stage':
        return {
          'appenders': [
            {
              'type': 'CONSOLE',
              'format': '[STAGING][%d][%sid][%l] %m',
              'level': 'DEBUG',
              'dateFormat': 'HH:mm:ss.SSS',
            },
            {
              'type': 'FILE',
              'format': '[%d][%did][%sid][%X{env}][%i][%l][%c] %m [%f]',
              'level': 'DEBUG',
              'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
              'filePattern': 'staging',
              'path': 'logs/',
              'rotationCycle': 'DAY',
            }
          ],
        };
      case 'prod':
      case 'production':
        return productionPro;
      default:
        return simple;
    }
  }

  // ============================================================
  // PRESET WITH CUSTOMIZATION - Builder pattern for presets
  // ============================================================

  /// Create a custom preset with device and session tracking
  static Map<String, dynamic> custom({
    Level consoleLevel = Level.INFO,
    Level? fileLevel,
    bool includeDeviceId = true,
    bool includeSessionId = true,
    bool includeAppVersion = false,
    bool includeStackTrace = false,
    bool includeTimestamp = true,
    String? filePath,
    String dateFormat = 'HH:mm:ss.SSS',
  }) {
    // Build format string based on options
    final formatParts = <String>[];
    if (includeTimestamp) formatParts.add('[%d]');
    if (includeAppVersion) formatParts.add('[%app]');
    if (includeDeviceId) formatParts.add('[%did]');
    if (includeSessionId) formatParts.add('[%sid]');
    formatParts.add('[%l]');
    if (includeStackTrace) formatParts.add('[%c]');
    formatParts.add('%m');
    if (includeStackTrace) formatParts.add('[%f]');

    final format = formatParts.join('');

    final appenders = <Map<String, dynamic>>[
      {
        'type': 'CONSOLE',
        'format': format,
        'level': consoleLevel.name,
        'dateFormat': dateFormat,
      }
    ];

    // Add file appender if requested
    if (fileLevel != null && filePath != null) {
      appenders.add({
        'type': 'FILE',
        'format': format,
        'level': fileLevel.name,
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'filePattern': 'app',
        'path': filePath,
        'rotationCycle': 'DAY',
      });
    }

    return {'appenders': appenders};
  }
}
