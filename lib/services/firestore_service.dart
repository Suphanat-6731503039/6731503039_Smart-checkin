
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {

  final db = FirebaseFirestore.instance;

  Future<void> saveCheckIn(Map<String,dynamic> data) async {
    await db.collection("checkins").add(data);
  }

  Future<void> saveCheckOut(Map<String,dynamic> data) async {
    await db.collection("checkouts").add(data);
  }

}
