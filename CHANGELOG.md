# Changelog

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