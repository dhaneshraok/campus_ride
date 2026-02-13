import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../constants/message_types.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _messagesRef(String rideId) {
    return _db.collection('rides').doc(rideId).collection('messages');
  }

  /// Send a text message
  Future<void> sendMessage({
    required String rideId,
    required String senderUid,
    required String senderName,
    required String senderAvatar,
    required String text,
    String? threadDriverUid,
  }) async {
    await _messagesRef(rideId).add({
      'sender_uid': senderUid,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'text': text,
      'type': MessageTypes.text,
      'thread_driver_uid': threadDriverUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Send a system message (e.g., "Ride accepted", "Ride started")
  Future<void> sendSystemMessage({
    required String rideId,
    required String text,
    String? threadDriverUid,
  }) async {
    await _messagesRef(rideId).add({
      'sender_uid': 'system',
      'sender_name': 'System',
      'sender_avatar': '',
      'text': text,
      'type': MessageTypes.system,
      'thread_driver_uid': threadDriverUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream messages for a ride (newest first)
  Stream<List<ChatMessage>> messagesStream(String rideId) {
    return _messagesRef(rideId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromDocument(d)).toList());
  }

  /// Get latest message for a ride (for inbox preview)
  Future<ChatMessage?> getLatestMessage(String rideId) async {
    final snap = await _messagesRef(rideId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ChatMessage.fromDocument(snap.docs.first);
  }

  /// Stream latest message for a ride (for live inbox preview)
  Stream<ChatMessage?> latestMessageStream(String rideId) {
    return _messagesRef(rideId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : ChatMessage.fromDocument(snap.docs.first));
  }

  /// Stream messages for a specific driver thread within a ride
  Stream<List<ChatMessage>> threadMessagesStream(
      String rideId, String driverUid) {
    return _messagesRef(rideId)
        .where('thread_driver_uid', isEqualTo: driverUid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromDocument(d)).toList());
  }

  /// Get latest message for a specific driver thread (for thread list preview)
  Future<ChatMessage?> getLatestThreadMessage(
      String rideId, String driverUid) async {
    final snap = await _messagesRef(rideId)
        .where('thread_driver_uid', isEqualTo: driverUid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ChatMessage.fromDocument(snap.docs.first);
  }

  /// Check if a ride has any messages
  Future<bool> hasMessages(String rideId) async {
    final snap = await _messagesRef(rideId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  /// Delete conversation messages for a ride.
  /// If [threadDriverUid] is provided, only that thread is deleted.
  Future<int> deleteConversation({
    required String rideId,
    String? threadDriverUid,
  }) async {
    var deletedCount = 0;
    const pageSize = 300;

    while (true) {
      Query query = _messagesRef(rideId);
      if (threadDriverUid != null) {
        query = query.where('thread_driver_uid', isEqualTo: threadDriverUid);
      }

      final snap = await query.limit(pageSize).get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      deletedCount += snap.docs.length;
      if (snap.docs.length < pageSize) break;
    }

    return deletedCount;
  }
}
