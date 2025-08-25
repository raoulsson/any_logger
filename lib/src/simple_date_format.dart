/// Simple date formatter that doesn't require the intl package
/// Supports common date format patterns used in logging
class SimpleDateFormat {
  final String pattern;

  SimpleDateFormat(this.pattern);

  String format(DateTime dateTime) {
    String result = pattern;

    // Year
    result =
        result.replaceAll('yyyy', dateTime.year.toString().padLeft(4, '0'));
    result = result.replaceAll(
        'yy', (dateTime.year % 100).toString().padLeft(2, '0'));

    // Month
    result = result.replaceAll('MM', dateTime.month.toString().padLeft(2, '0'));
    result = result.replaceAll('M', dateTime.month.toString());

    // Day
    result = result.replaceAll('dd', dateTime.day.toString().padLeft(2, '0'));
    result = result.replaceAll('d', dateTime.day.toString());

    // Hour (24-hour format)
    result = result.replaceAll('HH', dateTime.hour.toString().padLeft(2, '0'));
    result = result.replaceAll('H', dateTime.hour.toString());

    // Hour (12-hour format)
    int hour12 = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    result = result.replaceAll('hh', hour12.toString().padLeft(2, '0'));
    result = result.replaceAll('h', hour12.toString());

    // Minute
    result =
        result.replaceAll('mm', dateTime.minute.toString().padLeft(2, '0'));
    result = result.replaceAll('m', dateTime.minute.toString());

    // Second
    result =
        result.replaceAll('ss', dateTime.second.toString().padLeft(2, '0'));
    result = result.replaceAll('s', dateTime.second.toString());

    // Millisecond
    result = result.replaceAll(
        'SSS', dateTime.millisecond.toString().padLeft(3, '0'));
    result = result.replaceAll('S', dateTime.millisecond.toString());

    // AM/PM marker
    String amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    result = result.replaceAll('a', amPm);

    // Timezone offset (basic support)
    if (result.contains('Z')) {
      // For UTC time, show 'Z' or offset
      if (dateTime.isUtc) {
        result = result.replaceAll('Z', 'Z');
      } else {
        // Get local timezone offset
        final offset = dateTime.timeZoneOffset;
        final hours = offset.inHours.abs().toString().padLeft(2, '0');
        final minutes =
            (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
        final sign = offset.isNegative ? '-' : '+';
        result = result.replaceAll('Z', '$sign$hours:$minutes');
      }
    }

    // ISO 8601 'T' separator
    result = result.replaceAll('\'T\'', 'T');

    // Week day names (abbreviated)
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    result = result.replaceAll('EEE', weekDays[dateTime.weekday - 1]);

    // Week day names (full)
    const weekDaysFull = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    result = result.replaceAll('EEEE', weekDaysFull[dateTime.weekday - 1]);

    // Month names (abbreviated)
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    result = result.replaceAll('MMM', months[dateTime.month - 1]);

    // Month names (full)
    const monthsFull = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    result = result.replaceAll('MMMM', monthsFull[dateTime.month - 1]);

    return result;
  }

  /// Parse common date format patterns to a DateTime (basic implementation)
  /// This is a simplified parser - for full parsing, consider keeping intl
  static DateTime? parse(String input, String pattern) {
    // This is a basic implementation for common formats
    // For production use, you might want to keep intl for parsing
    try {
      // Try standard DateTime.parse first for ISO formats
      return DateTime.parse(input);
    } catch (_) {
      // For custom parsing, you'd need to implement pattern matching
      // This is complex and error-prone, so returning null for now
      return null;
    }
  }
}

/// Helper class to cache date formatters
class DateFormatCache {
  static final Map<String, SimpleDateFormat> _cache = {};

  static SimpleDateFormat getFormatter(String pattern) {
    return _cache.putIfAbsent(pattern, () => SimpleDateFormat(pattern));
  }

  static void clear() {
    _cache.clear();
  }
}

/// Extension method for convenient date formatting
extension DateTimeFormatting on DateTime {
  String format(String pattern) {
    return DateFormatCache.getFormatter(pattern).format(this);
  }
}
