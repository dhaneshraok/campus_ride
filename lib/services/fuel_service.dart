import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fuel_entry_model.dart';

class FuelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _entriesRef(String uid) =>
      _db.collection('users').doc(uid).collection('fuel_entries');

  /// Add a fuel entry
  Future<String> addEntry(String uid, FuelEntry entry) async {
    final doc = await _entriesRef(uid).add(entry.toJson());
    return doc.id;
  }

  /// Delete a fuel entry
  Future<void> deleteEntry(String uid, String entryId) async {
    await _entriesRef(uid).doc(entryId).delete();
  }

  /// Stream all fuel entries for a user, sorted by date descending
  Stream<List<FuelEntry>> entriesStream(String uid) {
    return _entriesRef(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FuelEntry.fromDocument(d)).toList());
  }
}
