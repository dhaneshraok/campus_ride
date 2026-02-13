import 'package:flutter_test/flutter_test.dart';
import 'package:campus_ride/utils/date_helpers.dart';

void main() {
  group('DateHelpers', () {
    group('formatTime', () {
      test('formats morning time', () {
        final dt = DateTime(2025, 3, 15, 9, 30);
        expect(DateHelpers.formatTime(dt), '9:30 AM');
      });

      test('formats afternoon time', () {
        final dt = DateTime(2025, 3, 15, 14, 45);
        expect(DateHelpers.formatTime(dt), '2:45 PM');
      });

      test('formats midnight as 12:00 AM', () {
        final dt = DateTime(2025, 3, 15, 0, 0);
        expect(DateHelpers.formatTime(dt), '12:00 AM');
      });

      test('formats noon as 12:00 PM', () {
        final dt = DateTime(2025, 3, 15, 12, 0);
        expect(DateHelpers.formatTime(dt), '12:00 PM');
      });
    });

    group('formatDate', () {
      test('formats date correctly', () {
        final dt = DateTime(2025, 3, 15);
        expect(DateHelpers.formatDate(dt), 'Mar 15, 2025');
      });

      test('formats single-digit day', () {
        final dt = DateTime(2025, 1, 5);
        expect(DateHelpers.formatDate(dt), 'Jan 5, 2025');
      });
    });

    group('formatDateTime', () {
      test('formats date and time', () {
        final dt = DateTime(2025, 3, 15, 14, 30);
        expect(DateHelpers.formatDateTime(dt), 'Mar 15, 2025 2:30 PM');
      });
    });

    group('formatDateTimeShort', () {
      test('formats short date and time', () {
        final dt = DateTime(2025, 3, 15, 14, 30);
        expect(DateHelpers.formatDateTimeShort(dt), '03/15 2:30 PM');
      });
    });

    group('isToday', () {
      test('returns true for today', () {
        expect(DateHelpers.isToday(DateTime.now()), isTrue);
      });

      test('returns true for today at different time', () {
        final now = DateTime.now();
        final todayMorning = DateTime(now.year, now.month, now.day, 6, 0);
        expect(DateHelpers.isToday(todayMorning), isTrue);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateHelpers.isToday(yesterday), isFalse);
      });

      test('returns false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateHelpers.isToday(tomorrow), isFalse);
      });
    });

    group('isTomorrow', () {
      test('returns true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowMidnight = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          10,
          0,
        );
        expect(DateHelpers.isTomorrow(tomorrowMidnight), isTrue);
      });

      test('returns false for today', () {
        expect(DateHelpers.isTomorrow(DateTime.now()), isFalse);
      });

      test('returns false for day after tomorrow', () {
        final dayAfter = DateTime.now().add(const Duration(days: 2));
        expect(DateHelpers.isTomorrow(dayAfter), isFalse);
      });
    });

    group('formatRelative', () {
      test('returns Just now for < 60 seconds', () {
        final recent = DateTime.now().subtract(const Duration(seconds: 30));
        expect(DateHelpers.formatRelative(recent), 'Just now');
      });

      test('returns minutes ago for < 60 minutes', () {
        final recent = DateTime.now().subtract(const Duration(minutes: 5));
        expect(DateHelpers.formatRelative(recent), '5m ago');
      });

      test('returns hours ago for < 24 hours', () {
        final recent = DateTime.now().subtract(const Duration(hours: 3));
        expect(DateHelpers.formatRelative(recent), '3h ago');
      });

      test('returns days ago for < 7 days', () {
        final recent = DateTime.now().subtract(const Duration(days: 2));
        expect(DateHelpers.formatRelative(recent), '2d ago');
      });

      test('returns formatted date for >= 7 days', () {
        final old = DateTime.now().subtract(const Duration(days: 10));
        final result = DateHelpers.formatRelative(old);
        // Should be a formatted date string, not "Xd ago"
        expect(result.contains('ago'), isFalse);
      });
    });

    group('formatPickupLabel', () {
      test('returns Today at TIME for today', () {
        final now = DateTime.now();
        final todayAt3 = DateTime(now.year, now.month, now.day, 15, 0);
        expect(DateHelpers.formatPickupLabel(todayAt3), 'Today at 3:00 PM');
      });

      test('returns Tomorrow at TIME for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowAt9 = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          9,
          30,
        );
        expect(
          DateHelpers.formatPickupLabel(tomorrowAt9),
          'Tomorrow at 9:30 AM',
        );
      });

      test('returns full date for other dates', () {
        final future = DateTime.now().add(const Duration(days: 5));
        final dt = DateTime(future.year, future.month, future.day, 14, 0);
        final result = DateHelpers.formatPickupLabel(dt);
        // Should not start with Today or Tomorrow
        expect(result.startsWith('Today'), isFalse);
        expect(result.startsWith('Tomorrow'), isFalse);
      });
    });
  });
}
