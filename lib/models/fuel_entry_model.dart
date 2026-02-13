import 'package:cloud_firestore/cloud_firestore.dart';

class FuelEntry {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;

  FuelEntry({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
    this.createdAt,
  });

  factory FuelEntry.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return FuelEntry(
      id: doc.id,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: json['notes'],
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
