import 'package:intl/intl.dart';

/// Format UTC timestamps from the API in India Standard Time (UTC+5:30).
DateTime toIst(DateTime dt) {
  final utc = dt.isUtc ? dt : dt.toUtc();
  return utc.add(const Duration(hours: 5, minutes: 30));
}

String formatIstDateTime(DateTime dt, {String pattern = 'd MMM yyyy, h:mm a'}) {
  return DateFormat(pattern).format(toIst(dt));
}

String formatIstDate(DateTime dt) => formatIstDateTime(dt, pattern: 'd MMM yyyy');

/// Parse API ISO strings as UTC when no offset is present.
DateTime parseApiDateTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return DateTime.now().toUtc();
  if (raw.endsWith('Z') || raw.contains('+') || raw.contains('-', 10)) {
    return parsed.toUtc();
  }
  return DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second);
}
