import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String reporterUid,
    required String reportedUid,
    String? rideId,
    required String reason,
    String? description,
  }) async {
    await _db.collection('reports').add({
      'reporter_uid': reporterUid,
      'reported_uid': reportedUid,
      'ride_id': rideId,
      'reason': reason,
      'description': description,
      'status': 'PENDING',
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
