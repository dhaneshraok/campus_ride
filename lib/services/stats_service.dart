import 'package:cloud_firestore/cloud_firestore.dart';

class StatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Count completed rides for a user (as rider + driver, deduplicated)
  Future<int> completedRideCount(String uid) async {
    final riderSnap = await _db
        .collection('rides')
        .where('rider_uid', isEqualTo: uid)
        .where('status', isEqualTo: 'COMPLETED')
        .get();
    final driverSnap = await _db
        .collection('rides')
        .where('driver_uid', isEqualTo: uid)
        .where('status', isEqualTo: 'COMPLETED')
        .get();

    final allIds = <String>{};
    for (final doc in riderSnap.docs) {
      allIds.add(doc.id);
    }
    for (final doc in driverSnap.docs) {
      allIds.add(doc.id);
    }
    return allIds.length;
  }
}
