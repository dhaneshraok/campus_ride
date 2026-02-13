import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String avatar;
  final bool isDriver;
  final String? carType;
  final String? carModel;
  final String? carPlate;
  final String? carColor;
  final int ratingSum;
  final int ratingCount;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isOnboarded;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.avatar = 'campus_owl',
    this.isDriver = false,
    this.carType,
    this.carModel,
    this.carPlate,
    this.carColor,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isOnboarded = false,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  double get averageRating => ratingCount > 0 ? ratingSum / ratingCount : 0.0;

  bool get hasRatings => ratingCount > 0;

  factory AppUser.fromJson(Map<String, dynamic> json, {String? id}) {
    return AppUser(
      uid: id ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? 'campus_owl',
      isDriver: json['is_driver'] ?? false,
      carType: json['car_type'],
      carModel: json['car_model'],
      carPlate: json['car_plate'],
      carColor: json['car_color'],
      ratingSum: json['rating_sum'] ?? 0,
      ratingCount: json['rating_count'] ?? 0,
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      isOnboarded: json['is_onboarded'] ?? false,
      fcmToken: json['fcm_token'],
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar': avatar,
      'is_driver': isDriver,
      'car_type': carType,
      'car_model': carModel,
      'car_plate': carPlate,
      'car_color': carColor,
      'rating_sum': ratingSum,
      'rating_count': ratingCount,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'is_onboarded': isOnboarded,
      'fcm_token': fcmToken,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {...toJson(), 'created_at': FieldValue.serverTimestamp()};
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phone,
    String? avatar,
    bool? isDriver,
    String? carType,
    String? carModel,
    String? carPlate,
    String? carColor,
    int? ratingSum,
    int? ratingCount,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isOnboarded,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isDriver: isDriver ?? this.isDriver,
      carType: carType ?? this.carType,
      carModel: carModel ?? this.carModel,
      carPlate: carPlate ?? this.carPlate,
      carColor: carColor ?? this.carColor,
      ratingSum: ratingSum ?? this.ratingSum,
      ratingCount: ratingCount ?? this.ratingCount,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
