import 'level.dart';
import 'logger_stack_trace.dart';
import 'simple_date_format.dart'; // Your new date formatter

class LogRecord {
  String? loggerName;
  final String? dateFormat;

  DateTime time;
  final String? tag;
  final Level level;
  final Object message; // Changed from String to Object to support lazy evaluation
  final Object? error;
  final StackTrace? stackTrace;
  final LoggerStackTrace contextInfo;

  // Cache parsed values
  String? _className;
  String? _methodName;
  int? _lineNumber; // Always store as int internally

  LogRecord(this.level, this.message, this.tag, this.contextInfo,
      {this.error, this.stackTrace, this.loggerName, this.dateFormat})
      : time = DateTime.now() {
    // Parse context info once during construction
    _parseContextInfo();
  }

  /// Parse the context info to extract class name, method name, and line number
  void _parseContextInfo() {
    String funcName = contextInfo.functionName;

    // IMPORTANT: Remove any file path that might be included
    // If functionName contains a colon followed by a path, extract just the function part
    if (funcName.contains(':')) {
      // Split by colon and take only the first part (before the path)
      final colonIndex = funcName.indexOf(':');
      funcName = funcName.substring(0, colonIndex);
    }

    // Now parse the clean function name
    // Handle closures and anonymous functions
    if (funcName.contains('closure') || funcName.contains('<anonymous>')) {
      _methodName = funcName;
      _className = '';
    } else {
      // Split by '.' to separate class and method
      final parts = funcName.split('.');

      if (parts.length >= 2) {
        // Has class and method
        _className = parts[parts.length - 2];
        _methodName = parts.last;
      } else if (parts.length == 1) {
        // Just method name, no class
        _methodName = parts.first;
        _className = '';
      }
    }

    // Convert lineNumber from String to int if needed
    _lineNumber = int.tryParse(contextInfo.lineNumber);
  }

  @override
  String toString() => '[${level.name}] $tag: $message';

  String getFormattedTime() {
    // Use SimpleDateFormat instead of intl's DateFormat
    return SimpleDateFormat(dateFormat ?? 'yyyy-MM-dd HH:mm:ss.SSS').format(time);
  }

  /// Returns formatted function name and line for %c placeholder
  /// Format: "ClassName.methodName:lineNumber" or just "methodName:lineNumber"
  String functionNameAndLine() {
    final parts = <String>[];

    // Add class name if available
    if (_className != null && _className!.isNotEmpty) {
      parts.add(_className!);
    }

    // Add method name if available
    if (_methodName != null && _methodName!.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add('.$_methodName');
      } else {
        parts.add(_methodName!);
      }
    }

    // Add line number if available
    if (_lineNumber != null && _lineNumber! > 0) {
      parts.add(':$_lineNumber');
    } else {
      // Fallback to contextInfo.lineNumber if _lineNumber is not set
      String lineStr;
      lineStr = contextInfo.lineNumber;

      if (lineStr.isNotEmpty && lineStr != '0') {
        parts.add(':$lineStr');
      }
    }

    // If we have nothing, return a default
    if (parts.isEmpty) {
      return 'unknown';
    }

    return parts.join('');
  }

  /// Returns the file location for %f placeholder
  /// Format: "package:example/path/file.dart(line:column)" or "file:///path/file.dart(line:column)"
  String? inFileLocation() {
    String location = contextInfo.fileName;

    // Convert absolute path to package path if possible
    if (!location.startsWith('package:') && !location.startsWith('dart:')) {
      location = _convertToPackagePath(location);
    }

    // Add line and column information if available
    int? lineNum;
    int? colNum;

    // Convert lineNumber to int if it's a string
    lineNum = int.tryParse(contextInfo.lineNumber);

    // Convert columnNumber to int if it's a string
    colNum = int.tryParse(contextInfo.columnNumber);

    if (lineNum != null && lineNum > 0) {
      final column = colNum ?? 5; // Default column to 5 if not available
      location = '$location($lineNum:$column)';
    }

    return location;
  }

  /// Convert absolute file path to package path if possible
  String _convertToPackagePath(String filePath) {
    // Handle file:// URLs
    if (filePath.startsWith('file:///')) {
      filePath = filePath.substring(8);

      // Windows fix: Handle drive letters properly
      // file:///C:/ becomes C:/
      // But on Unix, file:///home becomes /home
      if (filePath.length > 1 && filePath[0].toUpperCase() == filePath[0].toLowerCase()) {
        // Not a letter, so prepend the slash back for Unix paths
        if (!filePath.startsWith('/')) {
          filePath = '/$filePath';
        }
      }
    }

    // Handle Windows paths with backslashes
    filePath = filePath.replaceAll('\\', '/');

    // Try to convert to package path
    // Look for /lib/ in the path
    final libIndex = filePath.indexOf('/lib/');
    if (libIndex > 0) {
      // Extract package name from the path before /lib/
      final beforeLib = filePath.substring(0, libIndex);
      final parts = beforeLib.split('/');
      final packageName = parts.isNotEmpty ? parts.last : 'unknown';

      // Get the path after /lib/
      final afterLib = filePath.substring(libIndex + 5);

      return 'package:$packageName/$afterLib';
    }

    // Look for /test/ in the path (for test files)
    final testIndex = filePath.indexOf('/test/');
    if (testIndex > 0) {
      // Extract package name from the path before /test/
      final beforeTest = filePath.substring(0, testIndex);
      final parts = beforeTest.split('/');
      final packageName = parts.isNotEmpty ? parts.last : 'unknown';

      // Get the path after /test/
      final afterTest = filePath.substring(testIndex + 6);

      return 'package:$packageName/test/$afterTest';
    }

    // Look for /example/ in the path
    final exampleIndex = filePath.indexOf('/example/');
    if (exampleIndex > 0) {
      // Extract package name from the path before /example/
      final beforeExample = filePath.substring(0, exampleIndex);
      final parts = beforeExample.split('/');
      final packageName = parts.isNotEmpty ? parts.last : 'unknown';

      // Get the path after /example/
      final afterExample = filePath.substring(exampleIndex + 9);

      return 'package:$packageName/example/$afterExample';
    }

    // If we can't convert to package path, return as file:// URL
    if (!filePath.startsWith('file://')) {
      return 'file:///$filePath';
    }

    return filePath;
  }

  // Getters for parsed values
  String? get className => _className;

  String? get methodName => _methodName;

  int? get lineNumber => _lineNumber;
}
