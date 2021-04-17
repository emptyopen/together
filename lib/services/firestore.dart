import 'package:cloud_firestore/cloud_firestore.dart';

class Transactor {
  Transactor({this.sessionId});

  var _firestore = FirebaseFirestore.instance;
  String sessionId;

  transact(newData) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      transaction.set(postRef, newData);
    });
    await Future.delayed(Duration(milliseconds: 10));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
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

  transactInTheClubQuestion(playerIndex, question) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List playerRoundQuestion =
          snapshot.data()['player${playerIndex}Questions'];
      playerRoundQuestion.add(question);
      transaction.update(
          postRef, {'player${playerIndex}Questions': playerRoundQuestion});
    });
    await Future.delayed(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }

  transactInTheClubAnswer(playerIndex, answer) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      List questionAnswers = snapshot.data()['player${playerIndex}Answers'];
      questionAnswers.add(answer);
      transaction
          .update(postRef, {'player${playerIndex}Answers': questionAnswers});
    });
    await Future.delayed(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }

  transactInTheClubVote(playerIndex, word) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      Map votes = snapshot.data()['player${playerIndex}Votes'];
      if (votes.containsKey(word)) {
        votes[word] += 1;
      } else {
        votes[word] = 1;
      }
      transaction.update(postRef, {'player${playerIndex}Votes': votes});
    });
    await Future.delayed(Duration(milliseconds: 100));
    return (await _firestore.collection('sessions').doc(sessionId).get())
        .data();
  }
}
