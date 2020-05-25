import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {

  final CollectionReference sessionCollection = Firestore.instance.collection('sessions');

  Stream<QuerySnapshot> get sessions {
    return sessionCollection.snapshots();
  }
}