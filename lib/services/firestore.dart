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

  transactThreeCrownsDuelerCard(card) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      var duel = snapshot.data()['duel'];
      duel['duelerCard'] = card;
      transaction.update(postRef, {'duel': duel});
    });
  }

  transactThreeCrownsDueleeCard(card) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      var duel = snapshot.data()['duel'];
      duel['dueleeCard'] = card;
      transaction.update(postRef, {'duel': duel});
    });
  }

  transactAll(data) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      transaction.set(postRef, data);
    });
  }
}
