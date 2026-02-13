import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String reviewerUid;
  final String reviewerName;
  final String reviewerAvatar;
  final String rideId;
  final int stars;
  final String? comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.reviewerUid,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.rideId,
    required this.stars,
    this.comment,
    this.createdAt,
  });

  factory Review.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      reviewerUid: json['reviewer_uid'] ?? '',
      reviewerName: json['reviewer_name'] ?? '',
      reviewerAvatar: json['reviewer_avatar'] ?? '',
      rideId: json['ride_id'] ?? '',
      stars: json['stars'] ?? 0,
      comment: json['comment'],
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewer_uid': reviewerUid,
      'reviewer_name': reviewerName,
      'reviewer_avatar': reviewerAvatar,
      'ride_id': rideId,
      'stars': stars,
      'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
