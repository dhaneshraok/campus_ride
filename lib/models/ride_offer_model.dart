import 'package:cloud_firestore/cloud_firestore.dart';

class RideOffer {
  final String id;
  final String driverUid;
  final String driverName;
  final String driverAvatar;
  final String
  status; // 'pending', 'rider_confirmed', 'confirmed', 'declined', 'withdrawn'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RideOffer({
    required this.id,
    required this.driverUid,
    required this.driverName,
    required this.driverAvatar,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isRiderConfirmed => status == 'rider_confirmed';
  bool get isConfirmed => status == 'confirmed';
  bool get isDeclined => status == 'declined';
  bool get isWithdrawn => status == 'withdrawn';
  bool get isActive => isPending || isRiderConfirmed;

  factory RideOffer.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return RideOffer(
      id: doc.id,
      driverUid: json['driver_uid'] ?? '',
      driverName: json['driver_name'] ?? '',
      driverAvatar: json['driver_avatar'] ?? 'car_mcqueen',
      status: json['status'] ?? 'pending',
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_uid': driverUid,
      'driver_name': driverName,
      'driver_avatar': driverAvatar,
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {...toJson(), 'created_at': FieldValue.serverTimestamp()};
  }
}
