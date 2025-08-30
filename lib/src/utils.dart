import 'appender/rotation_cycle.dart';

class Utils {
  static RotationCycle getRotationCycleFromString(String? s) {
    return RotationCycle.values.firstWhere((e) => e.toString().split('.')[1].toLowerCase() == s!.toLowerCase(),
        orElse: () => RotationCycle.NEVER);
  }

  static int getCalendarWeek(DateTime date) {
    // ISO 8601 week number calculation
    // Find the Thursday of this week (weeks start on Monday in ISO 8601)
    int dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    DateTime thursday = date.add(Duration(days: 4 - dayOfWeek));

    // Find the first Thursday of the year
    DateTime jan1 = DateTime(thursday.year, 1, 1);
    int jan1DayOfWeek = jan1.weekday;
    DateTime firstThursday = jan1.add(Duration(days: (11 - jan1DayOfWeek) % 7));

    // Calculate week number
    int weekNumber = ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;

    return weekNumber;
  }
}
