import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import 'chat_service.dart';

class RideService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  CollectionReference get _ridesRef => _db.collection('rides');

  /// Create a new ride request
  Future<String> createRide(Ride ride) async {
    final doc = await _ridesRef.add(ride.toCreateJson());
    return doc.id;
  }

  /// Update an open ride's details
  Future<void> updateRide(String rideId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _ridesRef.doc(rideId).update(data);
  }

  /// Start a ride: ACCEPTED → IN_PROGRESS
  Future<void> startRide(String rideId) async {
    await _ridesRef.doc(rideId).update({
      'status': 'IN_PROGRESS',
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _chatService.sendSystemMessage(
      rideId: rideId,
      text: 'Ride started. Drive safe!',
    );
  }

  /// Complete a ride: IN_PROGRESS → COMPLETED
  Future<void> completeRide(String rideId) async {
    await _ridesRef.doc(rideId).update({
      'status': 'COMPLETED',
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _chatService.sendSystemMessage(
      rideId: rideId,
      text: 'Ride completed. Thanks for riding with Campus Ride!',
    );
  }

  /// Cancel a ride
  Future<void> cancelRide(
    String rideId,
    String cancelledByUid,
    String? reason,
  ) async {
    final ride = await getRide(rideId);

    await _ridesRef.doc(rideId).update({
      'status': 'CANCELLED',
      'cancelled_by': cancelledByUid,
      'cancel_reason': reason,
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (ride != null) {
      final cancellerName = cancelledByUid == ride.riderUid
          ? ride.riderName
          : (ride.driverName ?? 'Driver');

      await _chatService.sendSystemMessage(
        rideId: rideId,
        text: '$cancellerName cancelled this ride.${reason != null ? " Reason: $reason" : ""}',
      );
    }
  }

  /// Expire a ride: OPEN → CANCELLED (time passed)
  Future<void> expireRide(String rideId) async {
    await _ridesRef.doc(rideId).update({
      'status': 'CANCELLED',
      'cancelled_by': 'system',
      'cancel_reason': 'Ride expired — pickup time has passed.',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get all open rides that have expired (pickup time in the past)
  Future<List<Ride>> getExpiredOpenRides() async {
    final snap = await _ridesRef
        .where('status', isEqualTo: 'OPEN')
        .where('pickup_datetime', isLessThan: Timestamp.now())
        .get();
    return snap.docs.map((d) => Ride.fromDocument(d)).toList();
  }

  /// Get all users who are drivers
  Future<List<String>> getDriverUids() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('is_driver', isEqualTo: true)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// Stream all open rides (for browse screen)
  Stream<List<Ride>> openRidesStream() {
    return _ridesRef
        .where('status', isEqualTo: 'OPEN')
        .orderBy('pickup_datetime')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ride.fromDocument(d)).toList());
  }

  /// Stream rides where user is rider
  Stream<List<Ride>> riderRidesStream(String uid) {
    return _ridesRef
        .where('rider_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ride.fromDocument(d)).toList());
  }

  /// Stream rides where user is driver
  Stream<List<Ride>> driverRidesStream(String uid) {
    return _ridesRef
        .where('driver_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ride.fromDocument(d)).toList());
  }

  /// Stream active rides for a user (both as rider and driver)
  Stream<List<Ride>> activeRidesForUser(String uid) {
    return Stream.multi((controller) {
      List<Ride> riderRides = [];
      List<Ride> driverRides = [];

      void emit() {
        final combined = <Ride>[...riderRides, ...driverRides];
        final seen = <String>{};
        combined.retainWhere((r) => seen.add(r.id));
        controller.add(combined.where((r) => r.isActive).toList());
      }

      final riderSub = riderRidesStream(uid).listen(
        (rides) {
          riderRides = rides;
          emit();
        },
        onError: controller.addError,
      );

      final driverSub = driverRidesStream(uid).listen(
        (rides) {
          driverRides = rides;
          emit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await riderSub.cancel();
        await driverSub.cancel();
      };
    });
  }

  /// Log points for a participant on a completed ride
  Future<void> logPoints({
    required String rideId,
    required int points,
    required bool isDriver,
  }) async {
    final field = isDriver ? 'driver_points' : 'rider_points';
    await _ridesRef.doc(rideId).update({
      field: points,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Stream a single ride
  Stream<Ride> rideStream(String rideId) {
    return _ridesRef.doc(rideId).snapshots().map(
          (doc) => Ride.fromDocument(doc),
        );
  }

  /// Get a single ride
  Future<Ride?> getRide(String rideId) async {
    final doc = await _ridesRef.doc(rideId).get();
    if (!doc.exists) return null;
    return Ride.fromDocument(doc);
  }
}
