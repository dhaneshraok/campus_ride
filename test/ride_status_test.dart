import 'package:flutter_test/flutter_test.dart';
import 'package:campus_ride/constants/ride_status.dart';

void main() {
  group('RideStatus', () {
    group('label', () {
      test('open → OPEN', () {
        expect(RideStatus.open.label, 'OPEN');
      });
      test('accepted → ACCEPTED', () {
        expect(RideStatus.accepted.label, 'ACCEPTED');
      });
      test('inProgress → IN_PROGRESS', () {
        expect(RideStatus.inProgress.label, 'IN_PROGRESS');
      });
      test('completed → COMPLETED', () {
        expect(RideStatus.completed.label, 'COMPLETED');
      });
      test('cancelled → CANCELLED', () {
        expect(RideStatus.cancelled.label, 'CANCELLED');
      });
    });

    group('displayLabel', () {
      test('open → Open', () {
        expect(RideStatus.open.displayLabel, 'Open');
      });
      test('accepted → Accepted', () {
        expect(RideStatus.accepted.displayLabel, 'Accepted');
      });
      test('inProgress → In Progress', () {
        expect(RideStatus.inProgress.displayLabel, 'In Progress');
      });
      test('completed → Completed', () {
        expect(RideStatus.completed.displayLabel, 'Completed');
      });
      test('cancelled → Cancelled', () {
        expect(RideStatus.cancelled.displayLabel, 'Cancelled');
      });
    });

    group('fromString', () {
      test('parses OPEN', () {
        expect(RideStatus.fromString('OPEN'), RideStatus.open);
      });
      test('parses ACCEPTED', () {
        expect(RideStatus.fromString('ACCEPTED'), RideStatus.accepted);
      });
      test('parses IN_PROGRESS', () {
        expect(RideStatus.fromString('IN_PROGRESS'), RideStatus.inProgress);
      });
      test('parses COMPLETED', () {
        expect(RideStatus.fromString('COMPLETED'), RideStatus.completed);
      });
      test('parses CANCELLED', () {
        expect(RideStatus.fromString('CANCELLED'), RideStatus.cancelled);
      });
      test('defaults to open for unknown string', () {
        expect(RideStatus.fromString('UNKNOWN'), RideStatus.open);
      });
      test('defaults to open for empty string', () {
        expect(RideStatus.fromString(''), RideStatus.open);
      });
    });

    group('allowedTransitions', () {
      test('open → [accepted, cancelled]', () {
        expect(
          RideStatus.open.allowedTransitions,
          [RideStatus.accepted, RideStatus.cancelled],
        );
      });
      test('accepted → [inProgress, cancelled]', () {
        expect(
          RideStatus.accepted.allowedTransitions,
          [RideStatus.inProgress, RideStatus.cancelled],
        );
      });
      test('inProgress → [completed, cancelled]', () {
        expect(
          RideStatus.inProgress.allowedTransitions,
          [RideStatus.completed, RideStatus.cancelled],
        );
      });
      test('completed → [] (terminal state)', () {
        expect(RideStatus.completed.allowedTransitions, isEmpty);
      });
      test('cancelled → [] (terminal state)', () {
        expect(RideStatus.cancelled.allowedTransitions, isEmpty);
      });
    });

    group('icon', () {
      test('each status has a non-null icon', () {
        for (final status in RideStatus.values) {
          expect(status.icon, isNotNull);
        }
      });
    });

    group('color', () {
      test('each status has a non-null color', () {
        for (final status in RideStatus.values) {
          expect(status.color, isNotNull);
        }
      });
    });

    group('roundtrip label ↔ fromString', () {
      test('every status survives label → fromString roundtrip', () {
        for (final status in RideStatus.values) {
          expect(RideStatus.fromString(status.label), status);
        }
      });
    });
  });
}
