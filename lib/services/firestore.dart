import 'package:cloud_firestore/cloud_firestore.dart';

class Transactor {
  Transactor({this.sessionId});

  Firestore _firestore = Firestore.instance;
  String sessionId;

  transact(newData) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').document(sessionId);
      // DocumentSnapshot snapshot = await transaction.get(postRef);
      await transaction.set(postRef, newData);
    });
  }

  transactShowAndTellWords(newWord) async {
    print('hey');
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').document(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List messages = snapshot.data['words'];
      messages.add(newWord);
      await transaction.update(postRef, {'words': messages});
    });
  }
}
