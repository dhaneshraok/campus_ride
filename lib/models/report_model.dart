import 'package:cloud_firestore/cloud_firestore.dart';

class UserReport {
  final String id;
  final String reporterUid;
  final String reportedUid;
  final String? rideId;
  final String reason;
  final String? description;
  final String status;
  final DateTime? createdAt;

  UserReport({
    required this.id,
    required this.reporterUid,
    required this.reportedUid,
    this.rideId,
    required this.reason,
    this.description,
    this.status = 'PENDING',
    this.createdAt,
  });

  factory UserReport.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reporterUid: json['reporter_uid'] ?? '',
      reportedUid: json['reported_uid'] ?? '',
      rideId: json['ride_id'],
      reason: json['reason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'PENDING',
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporter_uid': reporterUid,
      'reported_uid': reportedUid,
      'ride_id': rideId,
      'reason': reason,
      'description': description,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
