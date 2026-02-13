import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String recipientUid;
  final String type;
  final String title;
  final String body;
  final String? rideId;
  final String? senderUid;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.recipientUid,
    required this.type,
    required this.title,
    required this.body,
    this.rideId,
    this.senderUid,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      recipientUid: json['recipient_uid'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      rideId: json['ride_id'],
      senderUid: json['sender_uid'],
      isRead: json['is_read'] ?? false,
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient_uid': recipientUid,
      'type': type,
      'title': title,
      'body': body,
      'ride_id': rideId,
      'sender_uid': senderUid,
      'is_read': isRead,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
