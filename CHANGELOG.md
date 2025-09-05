# Changelog

## 1.1.3

* **Enhanced Custom Logger Registration** - Fixed and improved named logger retrieval functionality
  - `Logger.defaultLogger()` now auto-registers named loggers for retrieval via `LoggerFactory.getLogger(name)`
  - Added new `LoggerFactory.createCustomLogger()` method for cleaner custom logger creation API
  - Custom loggers with names can now be retrieved from anywhere in the application using the same instance
  - Perfect for specialized logging (AI quality assessment, compliance auditing, financial exports, R&D analytics)
* **Improved Documentation for Specialized Loggers**
  - Clarified that custom loggers are independent instances requiring manual feeding
  - Added comprehensive example for AI quality assessment logging with export-ready format
  - Enhanced explanation of custom logger benefits and use cases
* **New Public API Methods**
  - `LoggerFactory.createCustomLogger(name, appenders)` - recommended way to create retrievable custom loggers
  - `LoggerFactory.registerCustomLogger(logger)` - manually register existing logger instances
* **Comprehensive Test Coverage**
  - Added full test suite for custom logger registration functionality
  - Tests cover both auto-registration and factory method approaches
  - Includes integration tests with file appenders and multiple logger scenarios
* **Backward Compatibility Maintained**
  - All existing APIs continue to work unchanged
  - No breaking changes to current logging configurations or usage patterns

## 1.1.2

* Formatter jittered README.md formatting. Fixed

## 1.1.1

* Added `clearOnStartup` configuration option for FileAppender
  - When enabled, log files are cleared on every app startup for fresh session logs
  - Available in LoggerBuilder.file(), FileAppender.fromConfig(), and FileAppenderBuilder
  - Defaults to `false` to maintain backward compatibility
* Enhanced documentation for creating independent "side loggers"  
  - Complete guide for creating separate loggers with their own file appenders
  - Real-world examples including audit logging and payment processing scenarios
  - Demonstrates how to isolate specific logging from main application logs
* Updated README with comprehensive FileAppender configuration table
* Added unit tests for IdProviderResolver

## 1.1.0

* Changes to get the Email Appender working

## 1.0.12

* Forcing IdProvider creation early to fail fast nicely if config is incorrect for file appender on flutter
* Adding getters for Appenders from LoggerFactory by string or type
* Changed LoggerBuilder to add Appenders instead of replacing existing ones

## 1.0.11

* Fixed FileAppender which did not work on Flutter platforms
* Critical bug fix in LogRecordFormatter. Format placeholders in %m now handled properly

## 1.0.10

* Updated README
* Improved self logging

## 1.0.9

* Updated README (No dependencies in core lib)

## 1.0.8

* Adding documentation on how to register this extension

## 1.0.7

* Some auto fix tool added a bug in ConsoleAppender

## 1.0.6

* Remove pubspec.lock from version control

## 1.0.5

* Updated README to reference extension packages through links
* Fixed issues reported by pano

## 1.0.4

* Added addAppenderConfig to LoggerBuilder

## 1.0.3

* Stabilized Flutter platform detection for best IdProvider implementation selection
* Uncluttered README

## 1.0.2

* Updated README

## 1.0.1

* Removed claim to be web compatible and amended README accordingly

## 1.0.0

* Initial release of Any Logger