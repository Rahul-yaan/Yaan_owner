class DateFormatter {
  /// Parses various date formats including ISO 8601 strings, "YYYY-MM-DD", "DD/MM/YYYY", "17 April 2024", etc.
  static DateTime? parseDate(String dateString) {
    if (dateString.isEmpty || dateString == 'N/A') return null;

    final parsed = DateTime.tryParse(dateString);
    if (parsed != null) {
      return parsed.toLocal();
    }

    // Try parsing "17 April 2024" or "17 April, 2024" or "17 Apr 2024"
    final regex = RegExp(r'(\d{1,2})\s+([a-zA-Z]+)[,\s]+(\d{4})');
    final match = regex.firstMatch(dateString);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final year = int.parse(match.group(3)!);

      int month = 1;
      const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      for (int i = 0; i < months.length; i++) {
        if (monthStr.startsWith(months[i])) {
          month = i + 1;
          break;
        }
      }
      return DateTime(year, month, day);
    }

    // Try parsing "YYYY-MM-DD" or "DD/MM/YYYY" or "DD-MM-YYYY"
    final regex2 = RegExp(r'(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})');
    final match2 = regex2.firstMatch(dateString);
    if (match2 != null) {
      final p1 = int.parse(match2.group(1)!);
      final p2 = int.parse(match2.group(2)!);
      final p3 = int.parse(match2.group(3)!);
      if (p1 > 1000) {
        return DateTime(p1, p2, p3);
      } else {
        return DateTime(p3, p2, p1);
      }
    }

    return null;
  }

  /// Formats a [DateTime] into a clean human-readable date format like "08 Aug 2026".
  static String formatDate(DateTime dt, {bool includeTime = false}) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayStr = dt.day.toString().padLeft(2, '0');
    final monthStr = months[dt.month - 1];
    final yearStr = dt.year.toString();

    if (includeTime && (dt.hour != 0 || dt.minute != 0)) {
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final hour12 = (dt.hour % 12 == 0) ? 12 : dt.hour % 12;
      final hourStr = hour12.toString().padLeft(2, '0');
      final minStr = dt.minute.toString().padLeft(2, '0');
      return '$dayStr $monthStr $yearStr, $hourStr:$minStr $period';
    }

    return '$dayStr $monthStr $yearStr';
  }

  /// Formats a raw slot string or date string into a user-friendly display string.
  /// If [checkIn] and [checkOut] are provided and distinct, formats as a date range e.g. "08 Aug 2026 - 09 Aug 2026".
  static String formatSlotDate(String raw, {String checkIn = '', String checkOut = ''}) {
    String valueToParse = raw;
    if (valueToParse.isEmpty || valueToParse == 'N/A') {
      if (checkIn.isNotEmpty) valueToParse = checkIn;
    }
    if (valueToParse.isEmpty || valueToParse == 'N/A') return 'N/A';

    final inDt = parseDate(checkIn.isNotEmpty ? checkIn : valueToParse);
    final outDt = parseDate(checkOut);

    if (inDt != null && outDt != null && !(inDt.year == outDt.year && inDt.month == outDt.month && inDt.day == outDt.day)) {
      return '${formatDate(inDt)} - ${formatDate(outDt)}';
    } else if (inDt != null) {
      return formatDate(inDt);
    }

    final dt = parseDate(valueToParse);
    if (dt != null) {
      return formatDate(dt, includeTime: true);
    }

    return valueToParse;
  }
}
