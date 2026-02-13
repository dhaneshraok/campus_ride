import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _db.collection('users');

  Future<void> createUser(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toCreateJson());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  Future<void> updateUser(AppUser user) async {
    await _usersRef.doc(user.uid).set(
      user.toJson(),
      SetOptions(merge: true),
    );
  }

  Future<void> updateFields(String uid, Map<String, dynamic> fields) async {
    fields['updated_at'] = FieldValue.serverTimestamp();
    await _usersRef.doc(uid).update(fields);
  }

  Stream<AppUser?> userStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
    });
  }

  Future<bool> userExists(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  }

  Future<void> setFcmToken(String uid, String token) async {
    await _usersRef.doc(uid).set({
      'fcm_token': token,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOnboarded(String uid) async {
    await _usersRef.doc(uid).update({
      'is_onboarded': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
