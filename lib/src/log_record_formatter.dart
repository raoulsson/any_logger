import 'dart:convert';

import '../any_logger.dart';

/// Optimized formatter with MDC pattern caching (no intl dependency)
class LogRecordFormatter {
  // Cache for parsed format templates
  static final Map<String, _FormatTemplate> _templateCache = {};
  static const int _maxCacheSize = 100;

  // Single compiled regex (created once)
  static final RegExp _mdcPattern = RegExp(r'%X\{([^}]+)\}');

  static String format(LogRecord logRecord, String format,
      {String? dateFormat = kDefaultDateFormat}) {
    var workingFormat = format;

    // CRITICAL: First extract and process the message to prevent double-evaluation
    // We need to handle %m FIRST and store the actual message
    String actualMessage = eval(logRecord.message);

    // Replace %m with a unique placeholder that won't be confused with other patterns
    const String messagePlaceholder = '<<__MESSAGE_CONTENT__>>';
    workingFormat = workingFormat.replaceAll('%m', messagePlaceholder);

    // NOW process all other placeholders (they won't affect the message content)

    // Handle device ID placeholder
    if (workingFormat.contains('%did')) {
      final deviceId = LoggerFactory.idProvider.deviceId ?? 'unknown';
      workingFormat = workingFormat.replaceAll('%did', deviceId);
    }

    // Handle session ID placeholder
    if (workingFormat.contains('%sid')) {
      final sessionId = LoggerFactory.idProvider.sessionId ?? 'unknown';
      workingFormat = workingFormat.replaceAll('%sid', sessionId);
    }

    // Handle app version placeholder
    if (workingFormat.contains('%app')) {
      final appVersion = LoggerFactory.appVersion ?? '';
      workingFormat = workingFormat.replaceAll('%app', appVersion);
    }

    // Handle timestamp
    if (workingFormat.contains('%d')) {
      var date = SimpleDateFormat(dateFormat!).format(logRecord.time);
      workingFormat = workingFormat.replaceAll('%d', date);
    }

    // Handle tag
    if (workingFormat.contains('%t')) {
      if (!isNullOrEmpty(logRecord.tag)) {
        workingFormat = workingFormat.replaceAll('%t', logRecord.tag!);
      } else {
        workingFormat = workingFormat.replaceAll('%t', '');
      }
    }

    // Handle logger name
    if (workingFormat.contains('%i')) {
      if (isNullOrEmpty(logRecord.loggerName)) {
        workingFormat = workingFormat.replaceAll('%i', '');
      } else {
        workingFormat = workingFormat.replaceAll('%i', logRecord.loggerName!);
      }
    }

    // Handle level
    if (workingFormat.contains('%l')) {
      workingFormat = workingFormat.replaceAll('%l', logRecord.level.name);
    }

    // Handle class.method:line format
    if (workingFormat.contains('%c')) {
      var classMethodLine = logRecord.functionNameAndLine();
      workingFormat = workingFormat.replaceAll('%c', classMethodLine);
    }

    // Handle file location
    if (workingFormat.contains('%f')) {
      var fileLocation = logRecord.inFileLocation();
      if (fileLocation != null) {
        workingFormat = workingFormat.replaceAll('%f', fileLocation);
      } else {
        workingFormat = workingFormat.replaceAll('%f', '');
      }
    }

    // Handle MDC placeholders like %X{env}
    if (workingFormat.contains('%X')) {
      workingFormat = _processMdcWithTemplateCache(workingFormat);
    }

    // FINALLY: Replace the message placeholder with the actual message
    // This ensures the message content is never evaluated for format placeholders
    workingFormat = workingFormat.replaceAll(messagePlaceholder, actualMessage);

    // Clean up any double spaces
    workingFormat = workingFormat.replaceAll('  ', ' ');

    return workingFormat;
  }

  static bool isNullOrEmpty(String? str) {
    return str == null || str.isEmpty;
  }

  /// Alternative: More aggressive caching with template parsing
  static String _processMdcWithTemplateCache(String format) {
    // Prevent unbounded growth
    if (_templateCache.length > _maxCacheSize) {
      _templateCache.clear();
    }

    // Get or create cached template
    var template = _templateCache.putIfAbsent(
      format,
      () => _FormatTemplate.parse(format),
    );

    // Apply MDC values to template
    return template.apply();
  }

  static String formatJson(LogRecord logRecord,
      {String? dateFormat = kDefaultDateFormat}) {
    var map = {
      // Use SimpleDateFormat instead of intl's DateFormat
      'time': SimpleDateFormat(dateFormat!).format(logRecord.time),
      'message': eval(logRecord.message),
      'level': logRecord.level.toString(),
      'tag': logRecord.tag,
      'logger': logRecord.loggerName,
      'location': logRecord.functionNameAndLine(),
      'file': logRecord.inFileLocation(),
      'deviceId': LoggerFactory.idProvider.deviceId,
      'sessionId': LoggerFactory.idProvider.sessionId,
      'appVersion': LoggerFactory.appVersion,
      'mdc': LoggerFactory.getAllMdcValues(),
    };

    if (logRecord.error != null) {
      map['error'] = logRecord.error.toString();
    }

    if (logRecord.stackTrace != null) {
      map['stackTrace'] = logRecord.stackTrace.toString();
    }

    return json.encode(map);
  }

  static String formatEmail(String? template, LogRecord logRecord,
      {String? dateFormat = kDefaultDateFormat}) {
    if (template == null) {
      return formatJson(logRecord, dateFormat: dateFormat);
    }
    return format(logRecord, template, dateFormat: dateFormat);
  }

  static String eval(Object message) {
    if (message is Function()) {
      return message().toString();
    } else if (message is String) {
      return message;
    }
    return message.toString();
  }
}

/// Template class for aggressive caching
class _FormatTemplate {
  final String originalFormat;
  final List<_TemplatePart> parts;

  _FormatTemplate(this.originalFormat, this.parts);

  static _FormatTemplate parse(String format) {
    var parts = <_TemplatePart>[];
    var lastIndex = 0;

    for (var match in LogRecordFormatter._mdcPattern.allMatches(format)) {
      // Add literal text before the match
      if (match.start > lastIndex) {
        parts.add(_LiteralPart(format.substring(lastIndex, match.start)));
      }

      // Add MDC placeholder
      var mdcKey = match.group(1)!;
      parts.add(_MdcPart(mdcKey));

      lastIndex = match.end;
    }

    // Add remaining literal text
    if (lastIndex < format.length) {
      parts.add(_LiteralPart(format.substring(lastIndex)));
    }

    return _FormatTemplate(format, parts);
  }

  String apply() {
    var buffer = StringBuffer();
    for (var part in parts) {
      buffer.write(part.getValue());
    }
    return buffer.toString();
  }
}

abstract class _TemplatePart {
  String getValue();
}

class _LiteralPart extends _TemplatePart {
  final String text;

  _LiteralPart(this.text);

  @override
  String getValue() => text;
}

class _MdcPart extends _TemplatePart {
  final String mdcKey;

  _MdcPart(this.mdcKey);

  @override
  String getValue() => LoggerFactory.getMdcValue(mdcKey) ?? '';
}
