import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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

  transactItem(itemName, item) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      transaction.update(postRef, {itemName: item});
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

  transactCharadeATroisJudgeList(judgeList) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      transaction.update(postRef, {'judgeList': judgeList});
    });
  }

  transactCharadeATroisStatePile(pile) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      String state = snapshot.data()['internalState'];
      transaction.update(postRef, {'${state}Pile': pile});
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

  transactSamesiesReady(playerId) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      transaction.update(postRef, {'ready$playerId': true});
    });
    sleep(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }

  transactSamesiesWord(playerId, word) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List playerWords = snapshot.data()['playerWords$playerId'];
      playerWords.add(word);
      transaction.update(postRef, {'playerWords$playerId': playerWords});
    });
    sleep(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }
}
