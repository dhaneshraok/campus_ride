import 'package:flutter_test/flutter_test.dart';
import 'package:campus_ride/models/user_model.dart';
import 'package:campus_ride/models/ride_model.dart';
import 'package:campus_ride/models/message_model.dart';
import 'package:campus_ride/constants/ride_status.dart';

void main() {
  group('AppUser', () {
    late AppUser user;

    setUp(() {
      user = AppUser(
        uid: 'uid1',
        email: 'test@students.rowan.edu',
        fullName: 'Test User',
        phone: '1234567890',
        avatar: '🦊',
        isDriver: true,
        carModel: 'Honda Civic',
        carPlate: 'ABC123',
        carColor: 'Blue',
        ratingSum: 14,
        ratingCount: 3,
        emergencyContactName: 'Mom',
        emergencyContactPhone: '9876543210',
        isOnboarded: true,
      );
    });

    group('averageRating', () {
      test('calculates correct average', () {
        expect(user.averageRating, closeTo(4.67, 0.01));
      });

      test('returns 0.0 when no ratings', () {
        final noRatings = AppUser(
          uid: 'uid2',
          email: 'a@students.rowan.edu',
          fullName: 'No Ratings',
        );
        expect(noRatings.averageRating, 0.0);
      });

      test('returns exact value for single rating', () {
        final single = AppUser(
          uid: 'uid3',
          email: 'b@students.rowan.edu',
          fullName: 'One Rating',
          ratingSum: 5,
          ratingCount: 1,
        );
        expect(single.averageRating, 5.0);
      });
    });

    group('hasRatings', () {
      test('returns true when ratingCount > 0', () {
        expect(user.hasRatings, isTrue);
      });

      test('returns false when ratingCount is 0', () {
        final noRatings = AppUser(
          uid: 'uid2',
          email: 'a@students.rowan.edu',
          fullName: 'No Ratings',
        );
        expect(noRatings.hasRatings, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with changed fields', () {
        final copy = user.copyWith(fullName: 'New Name', isDriver: false);
        expect(copy.fullName, 'New Name');
        expect(copy.isDriver, isFalse);
        // Unchanged fields
        expect(copy.uid, 'uid1');
        expect(copy.email, 'test@students.rowan.edu');
        expect(copy.avatar, '🦊');
        expect(copy.ratingSum, 14);
      });

      test('preserves all fields when no changes', () {
        final copy = user.copyWith();
        expect(copy.uid, user.uid);
        expect(copy.email, user.email);
        expect(copy.fullName, user.fullName);
        expect(copy.phone, user.phone);
        expect(copy.avatar, user.avatar);
        expect(copy.isDriver, user.isDriver);
        expect(copy.carModel, user.carModel);
        expect(copy.carPlate, user.carPlate);
        expect(copy.carColor, user.carColor);
        expect(copy.ratingSum, user.ratingSum);
        expect(copy.ratingCount, user.ratingCount);
        expect(copy.emergencyContactName, user.emergencyContactName);
        expect(copy.emergencyContactPhone, user.emergencyContactPhone);
        expect(copy.isOnboarded, user.isOnboarded);
      });
    });

    group('fromJson', () {
      test('parses full JSON correctly', () {
        final json = {
          'uid': 'uid1',
          'email': 'test@students.rowan.edu',
          'full_name': 'Test User',
          'phone': '1234567890',
          'avatar': '🐻',
          'is_driver': true,
          'car_model': 'Tesla',
          'car_plate': 'XYZ789',
          'car_color': 'Red',
          'rating_sum': 20,
          'rating_count': 5,
          'emergency_contact_name': 'Dad',
          'emergency_contact_phone': '5551234567',
          'is_onboarded': true,
          'fcm_token': 'token123',
        };
        final parsed = AppUser.fromJson(json);
        expect(parsed.uid, 'uid1');
        expect(parsed.email, 'test@students.rowan.edu');
        expect(parsed.fullName, 'Test User');
        expect(parsed.avatar, '🐻');
        expect(parsed.isDriver, isTrue);
        expect(parsed.carModel, 'Tesla');
        expect(parsed.ratingSum, 20);
        expect(parsed.ratingCount, 5);
        expect(parsed.isOnboarded, isTrue);
        expect(parsed.fcmToken, 'token123');
      });

      test('uses id parameter as uid when provided', () {
        final json = {'uid': 'old_uid', 'email': 'a@students.rowan.edu'};
        final parsed = AppUser.fromJson(json, id: 'doc_id');
        expect(parsed.uid, 'doc_id');
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{};
        final parsed = AppUser.fromJson(json);
        expect(parsed.uid, '');
        expect(parsed.email, '');
        expect(parsed.fullName, '');
        expect(parsed.phone, '');
        expect(parsed.avatar, 'campus_owl');
        expect(parsed.isDriver, isFalse);
        expect(parsed.carModel, isNull);
        expect(parsed.ratingSum, 0);
        expect(parsed.ratingCount, 0);
        expect(parsed.isOnboarded, isFalse);
      });
    });

    group('toJson', () {
      test('contains all expected keys', () {
        final json = user.toJson();
        expect(json['uid'], 'uid1');
        expect(json['email'], 'test@students.rowan.edu');
        expect(json['full_name'], 'Test User');
        expect(json['phone'], '1234567890');
        expect(json['avatar'], '🦊');
        expect(json['is_driver'], isTrue);
        expect(json['car_model'], 'Honda Civic');
        expect(json['car_plate'], 'ABC123');
        expect(json['car_color'], 'Blue');
        expect(json['rating_sum'], 14);
        expect(json['rating_count'], 3);
        expect(json['emergency_contact_name'], 'Mom');
        expect(json['emergency_contact_phone'], '9876543210');
        expect(json['is_onboarded'], isTrue);
      });
    });

    group('default values', () {
      test('defaults are applied correctly', () {
        final minimal = AppUser(
          uid: 'uid',
          email: 'test@students.rowan.edu',
          fullName: 'Name',
        );
        expect(minimal.phone, '');
        expect(minimal.avatar, 'campus_owl');
        expect(minimal.isDriver, isFalse);
        expect(minimal.carModel, isNull);
        expect(minimal.ratingSum, 0);
        expect(minimal.ratingCount, 0);
        expect(minimal.isOnboarded, isFalse);
        expect(minimal.fcmToken, isNull);
      });
    });
  });

  group('Ride', () {
    Ride createRide({
      RideStatus status = RideStatus.open,
      String? driverUid,
      String riderUid = 'rider1',
      bool riderRated = false,
      bool driverRated = false,
    }) {
      return Ride(
        id: 'ride1',
        riderUid: riderUid,
        riderName: 'Rider',
        riderAvatar: '🐻',
        driverUid: driverUid,
        driverName: driverUid != null ? 'Driver' : null,
        driverAvatar: driverUid != null ? '🦊' : null,
        destination: 'Student Center',
        pickupArea: 'Holly Pointe',
        pickupTime: '3:00 PM',
        pickupDatetime: DateTime(2025, 3, 15, 15, 0),
        status: status,
        riderRated: riderRated,
        driverRated: driverRated,
      );
    }

    group('isActive', () {
      test('OPEN is active', () {
        expect(createRide(status: RideStatus.open).isActive, isTrue);
      });
      test('ACCEPTED is active', () {
        expect(createRide(status: RideStatus.accepted).isActive, isTrue);
      });
      test('IN_PROGRESS is active', () {
        expect(createRide(status: RideStatus.inProgress).isActive, isTrue);
      });
      test('COMPLETED is not active', () {
        expect(createRide(status: RideStatus.completed).isActive, isFalse);
      });
      test('CANCELLED is not active', () {
        expect(createRide(status: RideStatus.cancelled).isActive, isFalse);
      });
    });

    group('hasDriver', () {
      test('returns true when driverUid is set', () {
        expect(createRide(driverUid: 'driver1').hasDriver, isTrue);
      });
      test('returns false when driverUid is null', () {
        expect(createRide().hasDriver, isFalse);
      });
    });

    group('canTransitionTo', () {
      test('OPEN can transition to ACCEPTED', () {
        expect(
          createRide(status: RideStatus.open)
              .canTransitionTo(RideStatus.accepted),
          isTrue,
        );
      });
      test('OPEN can transition to CANCELLED', () {
        expect(
          createRide(status: RideStatus.open)
              .canTransitionTo(RideStatus.cancelled),
          isTrue,
        );
      });
      test('OPEN cannot transition to COMPLETED', () {
        expect(
          createRide(status: RideStatus.open)
              .canTransitionTo(RideStatus.completed),
          isFalse,
        );
      });
      test('OPEN cannot transition to IN_PROGRESS', () {
        expect(
          createRide(status: RideStatus.open)
              .canTransitionTo(RideStatus.inProgress),
          isFalse,
        );
      });
      test('ACCEPTED can transition to IN_PROGRESS', () {
        expect(
          createRide(status: RideStatus.accepted)
              .canTransitionTo(RideStatus.inProgress),
          isTrue,
        );
      });
      test('IN_PROGRESS can transition to COMPLETED', () {
        expect(
          createRide(status: RideStatus.inProgress)
              .canTransitionTo(RideStatus.completed),
          isTrue,
        );
      });
      test('COMPLETED cannot transition to anything', () {
        final ride = createRide(status: RideStatus.completed);
        for (final target in RideStatus.values) {
          expect(ride.canTransitionTo(target), isFalse);
        }
      });
      test('CANCELLED cannot transition to anything', () {
        final ride = createRide(status: RideStatus.cancelled);
        for (final target in RideStatus.values) {
          expect(ride.canTransitionTo(target), isFalse);
        }
      });
    });

    group('isParticipant', () {
      test('returns true for rider', () {
        expect(createRide().isParticipant('rider1'), isTrue);
      });
      test('returns true for driver', () {
        expect(
          createRide(driverUid: 'driver1').isParticipant('driver1'),
          isTrue,
        );
      });
      test('returns false for non-participant', () {
        expect(createRide().isParticipant('stranger'), isFalse);
      });
    });

    group('isRider', () {
      test('returns true for rider uid', () {
        expect(createRide().isRider('rider1'), isTrue);
      });
      test('returns false for driver uid', () {
        expect(
          createRide(driverUid: 'driver1').isRider('driver1'),
          isFalse,
        );
      });
    });

    group('isDriver', () {
      test('returns true for driver uid', () {
        expect(
          createRide(driverUid: 'driver1').isDriver('driver1'),
          isTrue,
        );
      });
      test('returns false for rider uid', () {
        expect(createRide().isDriver('rider1'), isFalse);
      });
      test('returns false when no driver', () {
        expect(createRide().isDriver('anyone'), isFalse);
      });
    });

    group('default values', () {
      test('defaults are applied correctly', () {
        final ride = createRide();
        expect(ride.isUrgent, isFalse);
        expect(ride.status, RideStatus.open);
        expect(ride.cancelledBy, isNull);
        expect(ride.cancelReason, isNull);
        expect(ride.riderRated, isFalse);
        expect(ride.driverRated, isFalse);
      });
    });
  });

  group('ChatMessage', () {
    group('isSystem', () {
      test('returns true for system type', () {
        final msg = ChatMessage(
          id: 'msg1',
          senderUid: 'system',
          senderName: 'System',
          senderAvatar: '',
          text: 'Ride accepted',
          type: 'system',
        );
        expect(msg.isSystem, isTrue);
      });

      test('returns false for text type', () {
        final msg = ChatMessage(
          id: 'msg2',
          senderUid: 'user1',
          senderName: 'User',
          senderAvatar: '🐻',
          text: 'Hello!',
          type: 'text',
        );
        expect(msg.isSystem, isFalse);
      });

      test('defaults to text type', () {
        final msg = ChatMessage(
          id: 'msg3',
          senderUid: 'user1',
          senderName: 'User',
          senderAvatar: '🐻',
          text: 'Hi there',
        );
        expect(msg.type, 'text');
        expect(msg.isSystem, isFalse);
      });
    });
  });
}
