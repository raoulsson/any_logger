# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Any Logger is a powerful, flexible, and intuitive logging library for Dart and Flutter applications. It provides zero-configuration setup with progressive complexity - from simple console logging to enterprise-grade configurations with file rotation, HTTP endpoints, email notifications, and database logging through extension packages.

## Common Development Commands

### Testing
```bash
# Run all tests
dart test

# Run tests with coverage
dart test --coverage=coverage

# Run specific test files
dart test test/comprehensive_test_suite.dart
dart test test/integration_test_suite.dart

# Run tests for specific functionality
dart test test/appender_specific_tests.dart
dart test test/id_provider_resolver_tests.dart
```

### Code Analysis and Linting
```bash
# Analyze code (includes linting via flutter_lints)
dart analyze

# Analyze with fatal warnings (default behavior)
dart analyze --fatal-warnings

# Analyze treating info as fatal
dart analyze --fatal-infos
```

### Package Management
```bash
# Get dependencies
dart pub get

# Check dependency tree
dart pub deps

# Upgrade dependencies
dart pub upgrade
```

### Building and Publishing
```bash
# Dry run publish to check package
dart pub publish --dry-run

# Validate package structure
dart pub publish --dry-run --verbose
```

## High-Level Architecture

### Core Components

The library follows a factory pattern with a registry system for extensibility:

1. **LoggerFactory** (`lib/src/logger_factory.dart`) - Central singleton factory that manages logger instances and configuration. All logging setup goes through this class.

2. **Logger** (`lib/src/logger.dart`) - The actual logging class that processes log messages and sends them to registered appenders.

3. **Appenders** (`lib/src/appender/`) - Output destinations for log messages:
   - `ConsoleAppender` - Colored console output with stdout/stderr routing
   - `FileAppender` - File logging with rotation support (daily, weekly, monthly, size-based)
   - Extension appenders (JSON HTTP, Email, MySQL) available as separate packages

4. **AppenderRegistry** (`lib/src/appender/appender_registry.dart`) - Registry pattern enabling extension packages to register custom appender types.

5. **ID Providers** (`lib/src/id_provider/`) - Handle anonymous device/session tracking:
   - `FileIdProvider` - Persistent IDs (default on Dart console/server)
   - `MemIdProvider` - Memory-only IDs
   - `NullIdProvider` - No ID tracking
   - `IdProviderResolver` - Auto-selects appropriate provider based on platform

6. **Builders** (`lib/src/logger_builder.dart`, `lib/src/appender/*_builder.dart`) - Fluent API for configuration.

### Key Design Patterns

- **Singleton Factory**: `LoggerFactory` manages all logger instances globally
- **Registry Pattern**: `AppenderRegistry` allows extension packages to add new appender types
- **Builder Pattern**: Fluent configuration APIs for complex setups
- **Strategy Pattern**: Different ID providers for different platforms/needs
- **Mixin Pattern**: `AnyLogger` mixin adds logging capabilities to any class

### Extension Architecture

The core library is deliberately lightweight. Additional functionality comes through extension packages:
- `any_logger_json_http` - JSON over HTTP logging
- `any_logger_email` - Email notifications
- `any_logger_mysql` - MySQL database logging

Extensions register their appender types with `AppenderRegistry.instance.register()`.

### Platform Considerations

- **Flutter Apps**: Require `path_provider` for persistent device IDs (`%did` format pattern)
- **Dart Console/Server**: Work out-of-box with file-based ID persistence
- **Cross-Platform**: Automatic platform detection and appropriate ID provider selection

### Configuration Flow

1. `LoggerFactory.builder()` or convenience methods create configuration
2. Appenders are created via registered factories in `AppenderRegistry`
3. ID providers are resolved based on platform and requirements
4. Logger instances are cached and reused by name
5. Log records flow through formatters to appenders

### Testing Architecture

- Comprehensive test suite with integration, unit, and example usage tests
- Mock appenders and ID providers for isolated testing
- Platform-specific testing for ID provider resolution
- File system testing with temporary directories for file appenders