import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_offer_model.dart';
import '../models/user_model.dart';

class RideOfferService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _offersRef(String rideId) =>
      _db.collection('rides').doc(rideId).collection('offers');

  /// True if driver already has an active accepted/in-progress ride.
  Future<bool> driverHasActiveRide(
    String driverUid, {
    String? excludeRideId,
  }) async {
    final snap = await _db
        .collection('rides')
        .where('driver_uid', isEqualTo: driverUid)
        .where('status', whereIn: ['ACCEPTED', 'IN_PROGRESS'])
        .limit(5)
        .get();

    return snap.docs.any((d) => d.id != excludeRideId);
  }

  /// Create an offer (driver applies to a ride).
  /// Uses driverUid as doc ID to prevent duplicates.
  Future<bool> createOffer(String rideId, AppUser driver) async {
    if (await driverHasActiveRide(driver.uid)) {
      return false;
    }

    return await _db.runTransaction<bool>((txn) async {
      final rideDoc =
          await txn.get(_db.collection('rides').doc(rideId));
      if (!rideDoc.exists) return false;
      if (rideDoc['status'] != 'OPEN') return false;

      final offerDoc =
          await txn.get(_offersRef(rideId).doc(driver.uid));
      if (offerDoc.exists) return false; // already offered

      txn.set(_offersRef(rideId).doc(driver.uid), {
        'driver_uid': driver.uid,
        'driver_name': driver.fullName,
        'driver_avatar': driver.avatar,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  /// Withdraw an offer (driver cancels their offer while ride is OPEN).
  Future<void> withdrawOffer(String rideId, String driverUid) async {
    await _db.runTransaction((txn) async {
      final offerDoc =
          await txn.get(_offersRef(rideId).doc(driverUid));
      if (!offerDoc.exists) return;

      final status = offerDoc['status'] as String;
      if (status != 'pending' && status != 'rider_confirmed') return;

      txn.update(offerDoc.reference, {
        'status': 'withdrawn',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Rider confirms a driver (step 1 of mutual confirmation).
  Future<void> riderConfirmOffer(
      String rideId, String driverUid) async {
    await _offersRef(rideId).doc(driverUid).update({
      'status': 'rider_confirmed',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Driver confirms back (step 2 — mutual confirmation complete).
  /// Sets ride to ACCEPTED and writes driver info to ride doc.
  Future<bool> driverConfirmOffer(
      String rideId, AppUser driver) async {
    if (await driverHasActiveRide(driver.uid, excludeRideId: rideId)) {
      return false;
    }

    return await _db.runTransaction<bool>((txn) async {
      final rideDoc =
          await txn.get(_db.collection('rides').doc(rideId));
      if (!rideDoc.exists) return false;
      if (rideDoc['status'] != 'OPEN') return false;

      final offerDoc =
          await txn.get(_offersRef(rideId).doc(driver.uid));
      if (!offerDoc.exists) return false;
      if (offerDoc['status'] != 'rider_confirmed') return false;

      // Set ride to ACCEPTED with driver info
      txn.update(rideDoc.reference, {
        'driver_uid': driver.uid,
        'driver_name': driver.fullName,
        'driver_avatar': driver.avatar,
        'status': 'ACCEPTED',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Mark this offer as confirmed
      txn.update(offerDoc.reference, {
        'status': 'confirmed',
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  /// Decline all non-confirmed offers for a ride.
  /// Pass empty string for confirmedDriverUid to decline ALL offers.
  Future<void> declineOtherOffers(
      String rideId, String confirmedDriverUid) async {
    final snap = await _offersRef(rideId)
        .where('status', whereIn: ['pending', 'rider_confirmed']).get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      if (doc.id == confirmedDriverUid) continue;
      batch.update(doc.reference, {
        'status': 'declined',
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Stream all offers for a ride (ordered by creation time).
  Stream<List<RideOffer>> offersStream(String rideId) {
    return _offersRef(rideId)
        .orderBy('created_at')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RideOffer.fromDocument(d)).toList());
  }

  /// Stream a single driver's offer for a ride.
  Stream<RideOffer?> offerStream(String rideId, String driverUid) {
    return _offersRef(rideId).doc(driverUid).snapshots().map(
          (doc) => doc.exists ? RideOffer.fromDocument(doc) : null,
        );
  }

  /// Get list of declined driver UIDs for notification purposes.
  Future<List<String>> getDeclinedDriverUids(String rideId) async {
    final snap = await _offersRef(rideId)
        .where('status', isEqualTo: 'declined')
        .get();
    return snap.docs.map((d) => d['driver_uid'] as String).toList();
  }
}
