# Contributing to Any Logger

Thank you for your interest in contributing to Any Logger! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Documentation Standards](#documentation-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to maintain a welcoming and inclusive community.

## Project Structure

Any Logger uses a modular architecture:

```
any_logger/                    # Core package (Console & File appenders only)
├── lib/
│   ├── any_logger.dart       # Public API
│   └── src/
│       ├── core/             # Core functionality
│       └── appender/         # Appender implementations
└── test/

# Extension packages (separate repositories)
any_logger_json_http/          # JSON HTTP appender
any_logger_email/              # Email appender  
any_logger_mysql/              # MySQL appender
```

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Add the upstream repository as a remote
4. Create a new branch for your feature or fix

```bash
git clone https://github.com/yourusername/any_logger.git
cd any_logger
git remote add upstream https://github.com/raoulsson/any_logger.git
git checkout -b feature/your-feature-name
```

## Development Setup

1. Ensure you have Dart SDK 3.0.0 or higher installed
2. Install dependencies:
   ```bash
   dart pub get
   ```
3. Run tests to ensure everything works:
   ```bash
   dart test
   ```

## Making Changes

### Code Style

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `dart format` to format your code
- Run `dart analyze` to check for issues
- Keep line length under 80 characters where practical

### Architecture Guidelines

#### Core Package Philosophy
- **Minimal dependencies**: Core package should only depend on `crypto`
- **No network/database code**: These belong in extension packages
- **Flutter-compatible**: Must work with both Dart and Flutter

#### Adding New Appenders

New appenders should be created as **extension packages** unless they're fundamental (like Console/File).

##### For Core Appenders (rare):
1. Extend the `Appender` abstract class
2. Implement `createDeepCopy()` properly
3. Return a string from `getType()` (e.g., `'CONSOLE'`)
4. Register in `AppenderRegistry._registerCoreAppenders()`

##### For Extension Appenders (common):
1. Create a new package: `any_logger_your_appender`
2. Add minimal dependencies to the extension package
3. Register the appender when the package is imported:

```dart
// In any_logger_your_appender/lib/any_logger_your_appender.dart
import 'package:any_logger/any_logger.dart';

// Auto-register when imported
final _registered = () {
  AppenderRegistry.instance.register('YOUR_APPENDER', 
    (config, {test = false, date}) async {
      return YourAppender.fromConfig(config, test: test, date: date);
    });
  return true;
}();
```

#### Adding Builder Support

For new appenders, consider adding builder methods:

```dart
// In LoggerBuilder (for core appenders only)
LoggerBuilder yourAppender({required String param, Level level = Level.INFO}) {
  _appenderConfigs.add({
    'type': 'YOUR_APPENDER',
    'param': param,
    'level': level.name,
  });
  return this;
}

// Or create a specialized builder
class YourAppenderBuilder {
  // Builder implementation
}
```

### Performance Considerations

- Use early exit checks for log level filtering
- Implement lazy evaluation for expensive operations
- Cache frequently used computations (see `DateFormatCache`)
- Use batch processing for I/O operations
- Avoid dependencies on heavy packages

### Breaking Changes

When making breaking changes:
1. Document clearly in CHANGELOG.md
2. Provide migration guide
3. Consider compatibility shims for easier migration
4. Update major version number

## Documentation Standards

### Code Documentation

Every public API should have dartdoc comments:

```dart
/// A brief one-line description ending with a period.
///
/// Additional details that provide more context about the class,
/// method, or property. Can span multiple paragraphs.
///
/// Example usage:
/// ```dart
/// final logger = LoggerFactory.getLogger('MyLogger');
/// logger.info('Hello, world!');
/// ```
///
/// See also:
/// * [LoggerFactory] for creating loggers
/// * [Appender] for output destinations
class Logger {
  /// The name of this logger instance.
  ///
  /// Used to identify log sources and can be hierarchical
  /// using dot notation (e.g., 'app.service.database').
  final String name;
  
  /// Logs a message at the specified [level].
  ///
  /// The [message] can be a String or a Function that returns a String.
  /// Optional [tag] provides additional context.
  /// 
  /// Throws [ArgumentError] if message is null.
  void log(Level level, String message, {String? tag}) {
    // Implementation
  }
}
```

### README Updates

When adding features, update the README.md with:
- Feature description in the Features section
- Usage example in the appropriate section
- Configuration details if applicable
- Note if feature requires an extension package

### Extension Package Documentation

Each extension package should have its own README with:
- Installation instructions
- Dependencies required
- Usage examples
- Configuration options
- Link back to main package

### CHANGELOG Updates

Every change should be documented in CHANGELOG.md:
- Use semantic versioning
- Group changes by type (Added, Changed, Fixed, Deprecated, Removed)
- Include issue/PR numbers where applicable
- Note breaking changes prominently

## Testing

### Writing Tests

Tests should be:
- Comprehensive (aim for >80% coverage)
- Fast and isolated
- Well-named and documented
- Located in the `test/` directory
- Use `test: true` flag for appenders to avoid I/O

Example test structure:

```dart
import 'package:test/test.dart';
import 'package:any_logger/any_logger.dart';

void main() {
  group('Logger', () {
    setUp(() {
      // Setup code
    });

    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should log messages at correct level', () {
      // Arrange
      LoggerFactory.initSimpleConsole(level: Level.INFO);
      final logger = LoggerFactory.getRootLogger();
      
      // Act
      logger.logInfo('Test message');
      
      // Assert
      expect(logger.isInfoEnabled, isTrue);
    });
    
    test('should handle appender registration', () async {
      // Test with AppenderRegistry
      final registry = AppenderRegistry.instance;
      expect(registry.isRegistered('CONSOLE'), isTrue);
      expect(registry.isRegistered('FILE'), isTrue);
    });
  });
}
```

### Testing Extension Packages

Extension packages should:
1. Test registration with `AppenderRegistry`
2. Test with `test: true` flag to avoid actual I/O
3. Mock external dependencies (HTTP, SMTP, MySQL)
4. Test error handling and retry logic

### Running Tests

```bash
# Run all tests
dart test

# Run with coverage
dart test --coverage=coverage
dart pub global activate coverage
format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib

# Run specific test file
dart test test/logger_test.dart

# Run tests matching pattern
dart test --name "should log"
```

## Submitting Changes

### Pull Request Process

1. Update your branch with latest upstream changes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. Ensure all tests pass and coverage is maintained

3. Update documentation as needed

4. Submit a pull request with:
   - Clear title describing the change
   - Description of what and why
   - Reference to any related issues
   - Screenshots for UI changes (if applicable)

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Extension package

## Testing
- [ ] All tests pass
- [ ] Added new tests
- [ ] Updated documentation
- [ ] Tested with Flutter
- [ ] Tested with Dart console

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] CHANGELOG.md updated
- [ ] No new dependencies added to core (or justified if needed)
- [ ] Extension package created if adding network/database functionality
```

## Creating Extension Packages

If adding functionality that requires additional dependencies:

1. Create new package: `any_logger_<feature>`
2. Structure:
   ```
   any_logger_<feature>/
   ├── lib/
   │   ├── any_logger_<feature>.dart  # Main export with registration
   │   └── src/
   │       └── <feature>_appender.dart
   ├── test/
   ├── pubspec.yaml
   ├── README.md
   └── CHANGELOG.md
   ```

3. Register appender on import:
   ```dart
   // Auto-register when imported
   final _registered = () {
     AppenderRegistry.instance.register('YOUR_TYPE', factory);
     return true;
   }();
   ```

4. Publish to pub.dev as separate package

## Release Process

### Core Package Releases

Releases are managed by maintainers:

1. Update version in `pubspec.yaml`
2. Update CHANGELOG.md with release date
3. Create a git tag: `git tag v5.2.0`
4. Push tag: `git push upstream v5.2.0`
5. Publish to pub.dev: `dart pub publish`
6. Create GitHub release with changelog

### Extension Package Releases

Each extension package is versioned independently:

1. Can be released on different schedules
2. Should maintain compatibility with core package versions
3. Document minimum required core package version

## Migration Guides

When making breaking changes, provide migration guides:

```markdown
## Migration from v5.1 to v5.2

### Breaking Changes

1. AppenderType enum removed - use strings instead:
   ```dart
   // Old
   AppenderType.CONSOLE
   
   // New
   'CONSOLE'
   ```

2. Extension packages separated:
   ```yaml
   # Add only what you need
   dependencies:
     any_logger_json_http: ^1.0.0
   ```
```

## Getting Help

- Open an issue for bugs or feature requests
- Start a discussion for questions or ideas
- Email: hello@raoulsson.com

## Recognition

Contributors will be recognized in:
- The AUTHORS file
- Release notes for significant contributions
- The project README for major features

Thank you for contributing to Any Logger!