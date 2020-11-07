import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference sessionCollection =
      FirebaseFirestore.instance.collection('sessions');

  Stream<QuerySnapshot> get sessions {
    return sessionCollection.snapshots();
  }
}
