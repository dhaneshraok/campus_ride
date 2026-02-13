import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../constants/notification_types.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _notifRef => _db.collection('notifications');

  /// Create a notification
  Future<void> createNotification({
    required String recipientUid,
    required String type,
    required String title,
    required String body,
    String? rideId,
    String? senderUid,
  }) async {
    await _notifRef.add({
      'recipient_uid': recipientUid,
      'type': type,
      'title': title,
      'body': body,
      'ride_id': rideId,
      'sender_uid': senderUid,
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Stream notifications for a user
  Stream<List<AppNotification>> notificationsStream(String uid) {
    return _notifRef
        .where('recipient_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromDocument(d)).toList());
  }

  /// Stream unread count
  Stream<int> unreadCountStream(String uid) {
    return _notifRef
        .where('recipient_uid', isEqualTo: uid)
        .where('is_read', isEqualTo: false)
        .where('type', isEqualTo: NotificationTypes.newMessage)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notifId) async {
    await _notifRef.doc(notifId).update({'is_read': true});
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String uid) async {
    final snap = await _notifRef
        .where('recipient_uid', isEqualTo: uid)
        .where('is_read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  /// Mark unread message notifications as read.
  Future<void> markMessageNotificationsAsRead(
    String uid, {
    String? rideId,
  }) async {
    Query query = _notifRef
        .where('recipient_uid', isEqualTo: uid)
        .where('is_read', isEqualTo: false)
        .where('type', isEqualTo: NotificationTypes.newMessage);

    if (rideId != null) {
      query = query.where('ride_id', isEqualTo: rideId);
    }

    final snap = await query.get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }
}
