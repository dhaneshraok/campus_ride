import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/notification_types.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedAll() async {
    await _seedUsers();
    await _seedRides();
    await _seedReviews();
    await _seedNotifications();
  }

  Future<void> clearAll() async {
    final prefixes = ['seed_rider1', 'seed_rider2', 'seed_driver1', 'seed_driver2', 'seed_both1'];

    // Clear users and their reviews
    for (final uid in prefixes) {
      final reviews = await _db.collection('users').doc(uid).collection('reviews').get();
      for (final doc in reviews.docs) {
        await doc.reference.delete();
      }
      await _db.collection('users').doc(uid).delete();
    }

    // Clear seeded rides and their messages
    final rides = await _db.collection('rides').where('rider_uid', whereIn: prefixes).get();
    for (final doc in rides.docs) {
      final msgs = await doc.reference.collection('messages').get();
      for (final msg in msgs.docs) {
        await msg.reference.delete();
      }
      await doc.reference.delete();
    }

    // Clear seeded notifications
    final notifs = await _db.collection('notifications').where('recipient_uid', whereIn: prefixes).get();
    for (final doc in notifs.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _seedUsers() async {
    final users = [
      {
        'uid': 'seed_rider1',
        'email': 'alex@students.rowan.edu',
        'full_name': 'Alex Thompson',
        'phone': '856-555-0101',
        'avatar': '🦉',
        'is_driver': false,
        'rating_sum': 14,
        'rating_count': 3,
        'is_onboarded': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_rider2',
        'email': 'jordan@students.rowan.edu',
        'full_name': 'Jordan Smith',
        'phone': '856-555-0102',
        'avatar': '🎓',
        'is_driver': false,
        'rating_sum': 9,
        'rating_count': 2,
        'is_onboarded': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_driver1',
        'email': 'casey@students.rowan.edu',
        'full_name': 'Casey Williams',
        'phone': '856-555-0201',
        'avatar': '🚗',
        'is_driver': true,
        'car_model': '2022 Honda Civic',
        'car_plate': 'ABC-1234',
        'car_color': 'Silver',
        'rating_sum': 23,
        'rating_count': 5,
        'is_onboarded': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_driver2',
        'email': 'morgan@students.rowan.edu',
        'full_name': 'Morgan Davis',
        'phone': '856-555-0202',
        'avatar': '🦊',
        'is_driver': true,
        'car_model': '2023 Toyota Camry',
        'car_plate': 'XYZ-5678',
        'car_color': 'Blue',
        'rating_sum': 17,
        'rating_count': 4,
        'is_onboarded': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_both1',
        'email': 'riley@students.rowan.edu',
        'full_name': 'Riley Johnson',
        'phone': '856-555-0301',
        'avatar': '🚀',
        'is_driver': true,
        'car_model': '2021 Nissan Altima',
        'car_plate': 'DEF-9012',
        'car_color': 'White',
        'rating_sum': 9,
        'rating_count': 2,
        'is_onboarded': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final user in users) {
      await _db.collection('users').doc(user['uid'] as String).set(user);
    }
  }

  Future<void> _seedRides() async {
    final now = DateTime.now();
    final rides = <Map<String, dynamic>>[
      // OPEN rides
      {
        'rider_uid': 'seed_rider1',
        'rider_name': 'Alex Thompson',
        'rider_avatar': '🦉',
        'destination': 'Library',
        'pickup_area': 'Student Center',
        'pickup_time': '3:00 PM',
        'pickup_datetime': Timestamp.fromDate(now.add(const Duration(hours: 1))),
        'is_urgent': false,
        'status': 'OPEN',
        'rider_rated': false,
        'driver_rated': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'rider_uid': 'seed_rider2',
        'rider_name': 'Jordan Smith',
        'rider_avatar': '🎓',
        'destination': 'Engineering Hall',
        'pickup_area': 'Holly Pointe',
        'pickup_time': '4:30 PM',
        'pickup_datetime': Timestamp.fromDate(now.add(const Duration(hours: 2, minutes: 30))),
        'is_urgent': true,
        'status': 'OPEN',
        'rider_rated': false,
        'driver_rated': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'rider_uid': 'seed_both1',
        'rider_name': 'Riley Johnson',
        'rider_avatar': '🚀',
        'destination': 'Rowan Blvd',
        'pickup_area': 'Rec Center',
        'pickup_time': '5:00 PM',
        'pickup_datetime': Timestamp.fromDate(now.add(const Duration(hours: 3))),
        'is_urgent': false,
        'status': 'OPEN',
        'rider_rated': false,
        'driver_rated': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      // ACCEPTED ride
      {
        'rider_uid': 'seed_rider1',
        'rider_name': 'Alex Thompson',
        'rider_avatar': '🦉',
        'driver_uid': 'seed_driver1',
        'driver_name': 'Casey Williams',
        'driver_avatar': '🚗',
        'destination': 'Student Center',
        'pickup_area': 'Rowan Blvd',
        'pickup_time': '2:00 PM',
        'pickup_datetime': Timestamp.fromDate(now.add(const Duration(minutes: 30))),
        'is_urgent': false,
        'status': 'ACCEPTED',
        'rider_rated': false,
        'driver_rated': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      // IN_PROGRESS ride
      {
        'rider_uid': 'seed_rider2',
        'rider_name': 'Jordan Smith',
        'rider_avatar': '🎓',
        'driver_uid': 'seed_driver2',
        'driver_name': 'Morgan Davis',
        'driver_avatar': '🦊',
        'destination': 'Holly Pointe',
        'pickup_area': 'Library',
        'pickup_time': '1:30 PM',
        'pickup_datetime': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
        'is_urgent': false,
        'status': 'IN_PROGRESS',
        'rider_rated': false,
        'driver_rated': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      // COMPLETED rides
      {
        'rider_uid': 'seed_rider1',
        'rider_name': 'Alex Thompson',
        'rider_avatar': '🦉',
        'driver_uid': 'seed_driver1',
        'driver_name': 'Casey Williams',
        'driver_avatar': '🚗',
        'destination': 'Rec Center',
        'pickup_area': 'Engineering Hall',
        'pickup_time': '10:00 AM',
        'pickup_datetime': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'is_urgent': false,
        'status': 'COMPLETED',
        'rider_rated': true,
        'driver_rated': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'rider_uid': 'seed_rider2',
        'rider_name': 'Jordan Smith',
        'rider_avatar': '🎓',
        'driver_uid': 'seed_both1',
        'driver_name': 'Riley Johnson',
        'driver_avatar': '🚀',
        'destination': 'Library',
        'pickup_area': 'Student Center',
        'pickup_time': '9:00 AM',
        'pickup_datetime': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'is_urgent': false,
        'status': 'COMPLETED',
        'rider_rated': false,
        'driver_rated': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      // CANCELLED ride
      {
        'rider_uid': 'seed_both1',
        'rider_name': 'Riley Johnson',
        'rider_avatar': '🚀',
        'destination': 'Library',
        'pickup_area': 'Holly Pointe',
        'pickup_time': '8:00 AM',
        'pickup_datetime': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'is_urgent': false,
        'status': 'CANCELLED',
        'cancelled_by': 'seed_both1',
        'cancel_reason': 'Plans changed',
        'rider_rated': false,
        'driver_rated': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final ride in rides) {
      await _db.collection('rides').add(ride);
    }
  }

  Future<void> _seedReviews() async {
    final reviews = [
      {
        'userId': 'seed_driver1',
        'review': {
          'reviewer_uid': 'seed_rider1',
          'reviewer_name': 'Alex Thompson',
          'reviewer_avatar': '🦉',
          'ride_id': 'seed_ride_completed1',
          'stars': 5,
          'comment': 'Great driver, very friendly and safe!',
          'created_at': FieldValue.serverTimestamp(),
        },
      },
      {
        'userId': 'seed_driver2',
        'review': {
          'reviewer_uid': 'seed_rider2',
          'reviewer_name': 'Jordan Smith',
          'reviewer_avatar': '🎓',
          'ride_id': 'seed_ride_completed2',
          'stars': 4,
          'comment': 'Good ride, arrived on time.',
          'created_at': FieldValue.serverTimestamp(),
        },
      },
      {
        'userId': 'seed_rider1',
        'review': {
          'reviewer_uid': 'seed_driver1',
          'reviewer_name': 'Casey Williams',
          'reviewer_avatar': '🚗',
          'ride_id': 'seed_ride_completed1',
          'stars': 5,
          'comment': 'Pleasant rider, was ready at pickup.',
          'created_at': FieldValue.serverTimestamp(),
        },
      },
      {
        'userId': 'seed_rider2',
        'review': {
          'reviewer_uid': 'seed_driver2',
          'reviewer_name': 'Morgan Davis',
          'reviewer_avatar': '🦊',
          'ride_id': 'seed_ride_completed2',
          'stars': 4,
          'comment': 'Easy to find at pickup spot.',
          'created_at': FieldValue.serverTimestamp(),
        },
      },
    ];

    for (final entry in reviews) {
      await _db
          .collection('users')
          .doc(entry['userId'] as String)
          .collection('reviews')
          .add(entry['review'] as Map<String, dynamic>);
    }
  }

  Future<void> _seedNotifications() async {
    final notifs = [
      {
        'recipient_uid': 'seed_rider1',
        'type': NotificationTypes.rideAccepted,
        'title': 'Ride Accepted!',
        'body': 'Casey Williams accepted your ride to Student Center.',
        'sender_uid': 'seed_driver1',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'recipient_uid': 'seed_rider2',
        'type': NotificationTypes.rideStarted,
        'title': 'Ride Started',
        'body': 'Morgan Davis is on the way!',
        'sender_uid': 'seed_driver2',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'recipient_uid': 'seed_driver1',
        'type': NotificationTypes.newReview,
        'title': 'New Rating',
        'body': 'Alex Thompson rated you 5 stars!',
        'sender_uid': 'seed_rider1',
        'is_read': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'recipient_uid': 'seed_driver2',
        'type': NotificationTypes.newRide,
        'title': 'New Ride Request',
        'body': 'New ride request near Engineering Hall.',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final notif in notifs) {
      await _db.collection('notifications').add(notif);
    }
  }
}
