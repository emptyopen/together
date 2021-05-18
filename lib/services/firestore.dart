import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/screens/in_the_club/in_the_club_services.dart';

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

  transactInTheClubQuestion(playerIndex, question, answers) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);
      DocumentSnapshot snapshot = await transaction.get(postRef);
      Map data = snapshot.data();
      Map playerQuestions = data['player${playerIndex}Questions'];
      String phase = data['phase'];
      playerQuestions[question] = answers;

      // check if all players are done, if so set phase to clubSelection
      bool allPlayersDone = true;
      data['playerIds'].asMap().forEach((i, playerId) {
        if (i != playerIndex &&
            data['player${i}Questions'].length <
                data['rules']['numQuestionsPerPlayer']) {
          allPlayersDone = false;
        }
      });
      Map clubMembership = {};
      if (allPlayersDone) {
        // check if question collection round is at max
        phase = 'clubSelection';
        getQuestions(data)[data['clubSelectionQuestionIndex']]
            .values
            .toList()[0]
            .forEach((answer) {
          clubMembership[answer] = [];
        });
      }
      transaction.update(postRef, {
        'player${playerIndex}Questions': playerQuestions,
        'phase': phase,
        'clubMembership': clubMembership,
      });
    });
  }

  transactInTheClubPlayerReady(playerIndex) async {
    await _firestore.runTransaction((transaction) async {
      DocumentReference postRef =
          _firestore.collection('sessions').doc(sessionId);

      DocumentSnapshot snapshot = await transaction.get(postRef);
      Map data = snapshot.data();

      data['player${playerIndex}Ready'] = true;

      // check if all players are ready
      bool allPlayersReady = true;
      data['playerIds'].asMap().forEach((i, playerId) {
        if (!data['player${i}Ready']) {
          allPlayersReady = false;
        }
      });
      int numQuestions = getQuestions(data).length;
      if (allPlayersReady) {
        if (data['clubSelectionQuestionIndex'] < numQuestions - 1) {
          data['clubSelectionQuestionIndex'] += 1;
          // reset values
          data['playerIds'].asMap().forEach((i, playerId) {
            data['player${i}Ready'] = false;
          });
          data['clubMembership'] = {};
          getQuestions(data)[data['clubSelectionQuestionIndex']]
              .values
              .toList()[0]
              .forEach((answer) {
            data['clubMembership'][answer] = [];
          });
        } else {
          if (data['rules']['numWouldYouRather'] > 0) {
            data['phase'] = 'wouldYouRather';
            data['wouldYouRatherQuestionIndex'] = 0;
            // initialize club membership
            data['playerIds'].asMap().forEach((i, playerId) {
              data['player${i}Ready'] = false;
            });
            data['clubMembership'] = {};
            data['wouldYouRatherQuestions']['0'].forEach((answer) {
              data['clubMembership'][answer] = [];
            });
          } else {
            data['phase'] = 'scoreboard';
          }
        }
      }

      Map<String, dynamic> updateTerms = {
        'phase': data['phase'],
        'clubMembership': data['clubMembership'],
        'clubSelectionQuestionIndex': data['clubSelectionQuestionIndex'],
      };

      data['playerIds'].asMap().forEach((i, playerId) {
        updateTerms['player${i}Ready'] = data['player${i}Ready'];
      });

      print('tra: $updateTerms');

      transaction.update(postRef, updateTerms);
    });
  }
}
