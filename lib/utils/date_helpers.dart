import 'package:intl/intl.dart';

class DateHelpers {
  DateHelpers._();

  static String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy h:mm a').format(dt);
  }

  static String formatDateTimeShort(DateTime dt) {
    return DateFormat('MM/dd h:mm a').format(dt);
  }

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return formatDate(dt);
    }
  }

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static bool isTomorrow(DateTime dt) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
  }

  static String formatPickupLabel(DateTime dt) {
    if (isToday(dt)) {
      return 'Today at ${formatTime(dt)}';
    } else if (isTomorrow(dt)) {
      return 'Tomorrow at ${formatTime(dt)}';
    }
    return formatDateTime(dt);
  }
}
