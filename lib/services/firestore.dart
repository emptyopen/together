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

  transactThreeCrownsDuelerCard(card, playerIndex, i) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List playerHand = snapshot.data()['player${playerIndex}Hand'];
      playerHand.removeAt(i);
      transaction.update(postRef, {
        'duelerCard': card,
        'player${playerIndex}Hand': playerHand,
      });
    });
    await Future.delayed(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }

  transactThreeCrownsDueleeCard(card, playerIndex, i) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List playerHand = snapshot.data()['player${playerIndex}Hand'];
      playerHand.removeAt(i);
      transaction.update(postRef, {
        'dueleeCard': card,
        'player${playerIndex}Hand': playerHand,
      });
    });
    await Future.delayed(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }

  transactSamesiesReady(playerId) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      transaction.update(postRef, {'ready$playerId': true});
    });
    await Future.delayed(Duration(milliseconds: 100));
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
    await Future.delayed(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }

  transactInTheClubQuestion(playerId, question) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List playerRoundQuestion = snapshot.data()['player${playerId}Questions'];
      playerRoundQuestion.add(question);
      transaction
          .update(postRef, {'player${playerId}Questions': playerRoundQuestion});
    });
    await Future.delayed(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }
}
