import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/ride_status.dart';

class Ride {
  final String id;
  final String riderUid;
  final String riderName;
  final String riderAvatar;
  final String? driverUid;
  final String? driverName;
  final String? driverAvatar;
  final String destination;
  final String pickupArea;
  final String? pickupAddress;
  final String pickupTime;
  final DateTime pickupDatetime;
  final bool isUrgent;
  final RideStatus status;
  final String? cancelledBy;
  final String? cancelReason;
  final bool riderRated;
  final bool driverRated;
  final int? driverPoints;
  final int? riderPoints;
  final int offerCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ride({
    required this.id,
    required this.riderUid,
    required this.riderName,
    required this.riderAvatar,
    this.driverUid,
    this.driverName,
    this.driverAvatar,
    required this.destination,
    required this.pickupArea,
    this.pickupAddress,
    required this.pickupTime,
    required this.pickupDatetime,
    this.isUrgent = false,
    this.status = RideStatus.open,
    this.cancelledBy,
    this.cancelReason,
    this.riderRated = false,
    this.driverRated = false,
    this.driverPoints,
    this.riderPoints,
    this.offerCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive =>
      status == RideStatus.open ||
      status == RideStatus.accepted ||
      status == RideStatus.inProgress;
  bool get isStaleOpenRide =>
      status == RideStatus.open && pickupDatetime.isBefore(DateTime.now());

  bool get hasDriver => driverUid != null;
  bool get hasDriverPoints => driverPoints != null;
  bool get hasRiderPoints => riderPoints != null;
  bool get hasOffers => offerCount > 0;

  bool canTransitionTo(RideStatus target) =>
      status.allowedTransitions.contains(target);

  bool isParticipant(String uid) => riderUid == uid || driverUid == uid;

  bool isRider(String uid) => riderUid == uid;
  bool isDriver(String uid) => driverUid == uid;

  factory Ride.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return Ride(
      id: doc.id,
      riderUid: json['rider_uid'] ?? '',
      riderName: json['rider_name'] ?? '',
      riderAvatar: json['rider_avatar'] ?? 'campus_owl',
      driverUid: json['driver_uid'],
      driverName: json['driver_name'],
      driverAvatar: json['driver_avatar'],
      destination: json['destination'] ?? '',
      pickupArea: json['pickup_area'] ?? '',
      pickupAddress: json['pickup_address'],
      pickupTime: json['pickup_time'] ?? '',
      pickupDatetime:
          (json['pickup_datetime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUrgent: json['is_urgent'] ?? false,
      status: RideStatus.fromString(json['status'] ?? 'OPEN'),
      cancelledBy: json['cancelled_by'],
      cancelReason: json['cancel_reason'],
      riderRated: json['rider_rated'] ?? false,
      driverRated: json['driver_rated'] ?? false,
      driverPoints: json['driver_points'],
      riderPoints: json['rider_points'],
      offerCount: json['offer_count'] ?? 0,
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rider_uid': riderUid,
      'rider_name': riderName,
      'rider_avatar': riderAvatar,
      'driver_uid': driverUid,
      'driver_name': driverName,
      'driver_avatar': driverAvatar,
      'destination': destination,
      'pickup_area': pickupArea,
      'pickup_address': pickupAddress,
      'pickup_time': pickupTime,
      'pickup_datetime': Timestamp.fromDate(pickupDatetime),
      'is_urgent': isUrgent,
      'status': status.label,
      'cancelled_by': cancelledBy,
      'cancel_reason': cancelReason,
      'rider_rated': riderRated,
      'driver_rated': driverRated,
      'driver_points': driverPoints,
      'rider_points': riderPoints,
      'offer_count': offerCount,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {...toJson(), 'created_at': FieldValue.serverTimestamp()};
  }
}
