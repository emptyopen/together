import 'package:cloud_firestore/cloud_firestore.dart';

class Transactor {
  Transactor({this.sessionId});

  var _firestore = FirebaseFirestore.instance;
  String sessionId;

  transact(newData) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      // DocumentSnapshot snapshot = await transaction.get(postRef);
      transaction.set(postRef, newData);
    });
  }

  transactCharadeATroisWords(newWord) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List words = snapshot.data()['words'];
      words.add(newWord);
      transaction.update(postRef, {'words': words});
    });
  }

  transactPlotTwistMessage(newText) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List texts = snapshot.data()['texts'];
      texts.add(newText);
      transaction.update(postRef, {'texts': texts});
    });
  }
}
