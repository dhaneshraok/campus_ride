import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderAvatar;
  final String text;
  final String type; // 'text' or 'system'
  final String? threadDriverUid; // driver UID for per-driver chat threads
  final DateTime? timestamp;

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    this.type = 'text',
    this.threadDriverUid,
    this.timestamp,
  });

  bool get isSystem => type == 'system';

  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderUid: json['sender_uid'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderAvatar: json['sender_avatar'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      threadDriverUid: json['thread_driver_uid'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_uid': senderUid,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'text': text,
      'type': type,
      'thread_driver_uid': threadDriverUid,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
