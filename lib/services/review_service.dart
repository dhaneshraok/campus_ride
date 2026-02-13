import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a review — batch write for atomicity
  Future<void> submitReview({
    required String reviewedUid,
    required String reviewerUid,
    required String reviewerName,
    required String reviewerAvatar,
    required String rideId,
    required int stars,
    String? comment,
    required bool isRiderRating, // true = rider is rating driver
  }) async {
    final batch = _db.batch();

    // 1. Add review to reviewed user's subcollection
    final reviewRef = _db
        .collection('users')
        .doc(reviewedUid)
        .collection('reviews')
        .doc();
    batch.set(reviewRef, {
      'reviewer_uid': reviewerUid,
      'reviewer_name': reviewerName,
      'reviewer_avatar': reviewerAvatar,
      'ride_id': rideId,
      'stars': stars,
      'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. Increment rating aggregates on user doc
    final userRef = _db.collection('users').doc(reviewedUid);
    batch.update(userRef, {
      'rating_sum': FieldValue.increment(stars),
      'rating_count': FieldValue.increment(1),
    });

    // 3. Mark ride as rated by this role
    final rideRef = _db.collection('rides').doc(rideId);
    batch.update(rideRef, {
      isRiderRating ? 'rider_rated' : 'driver_rated': true,
    });

    await batch.commit();
  }

  /// Get all reviews for a user
  Stream<List<Review>> reviewsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Review.fromDocument(d)).toList());
  }

  /// Check if user has already reviewed this ride
  Future<bool> hasReviewedRide(String userId, String rideId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .where('ride_id', isEqualTo: rideId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
