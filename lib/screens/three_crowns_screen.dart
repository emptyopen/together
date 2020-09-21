import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:together/services/services.dart';
import 'package:together/services/three_crowns_services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'lobby_screen.dart';
import 'package:together/components/log.dart';
import 'package:together/components/end_game.dart';

class ThreeCrownsScreen extends StatefulWidget {
  ThreeCrownsScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _ThreeCrownsScreenState createState() => _ThreeCrownsScreenState();
}

class _ThreeCrownsScreenState extends State<ThreeCrownsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Map selectedTiles = {};

  checkIfExit(data) async {
    // run async func to check if game is over, or back to lobby or deleted (main menu)
    if (data == null) {
      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      // I DON'T KNOW WHY WE NEED THIS BUT OTHERWISE WE GET DEBUG LOCKED ISSUES
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .setData(data);

      // navigate to lobby
      Navigator.of(context).pop();
      slideTransition(
        context,
        LobbyScreen(
          roomCode: widget.roomCode,
        ),
      );
    }
  }

  returnCard(data) async {
    // check if both cards are played, if so show snackbar (duel already started!)
    if (data['duel']['duelerCard'] != '' && data['duel']['dueleeCard'] != '') {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Duel has already started!'),
        duration: Duration(seconds: 3),
      ));
      // return;
    }
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if (playerIndex == data['duel']['duelerIndex']) {
      // player is dueler
      data['player${playerIndex}Hand'].add(data['duel']['duelerCard']);
      data['duel']['duelerCard'] = '';
    } else {
      data['player${playerIndex}Hand'].add(data['duel']['dueleeCard']);
      data['duel']['dueleeCard'] = '';
    }
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  setWinner(winnerIndex, data) {
    data['duel']['winnerIndexes'] = [winnerIndex];
    var name = playerNameFromIndex(winnerIndex, data);
    if (winnerIndex == data['duelerIndex']) {
      data['log'].add(
          '$name wins: ${data['duel']['duelerCard']} beats ${data['duel']['dueleeCard']}');
    } else {
      data['log'].add(
          '$name wins: ${data['duel']['dueleeCard']} beats ${data['duel']['duelerCard']}');
    }
  }

  determineDuelWinner(data) async {
    print('determining winner');

    // set up values
    bool flipWinners = false;
    String duelerValue = data['duel']['duelerCard'][0];
    String duelerSuit = data['duel']['duelerCard'][1];
    String dueleeValue = data['duel']['dueleeCard'][0];
    String dueleeSuit = data['duel']['dueleeCard'][1];
    // check for same suit
    if (duelerSuit == dueleeSuit) {
      flipWinners = !flipWinners;
    }
    // flip for any 4
    if (duelerValue == '4' || dueleeValue == '4') {
      flipWinners = !flipWinners;
    }
    bool letterCardInvolved = ['K', 'Q', 'J'].contains(dueleeValue) ||
        ['K', 'Q', 'J'].contains(duelerValue);
    bool oneCardInvolved = dueleeValue == '1' || duelerValue == '1';

    // if there is a value tie, immediately move to next joust
    if (duelerValue == dueleeValue) {
      print('joust');
      data['duel']['joust'] += 1;
      if (data['duel']['joust'] >= 4) {
        data['log'].add('Three jousts! Both players get 3 tiles.');
        data['duel']['winnerIndexes'] = [
          data['duel']['duelerIndex'],
          data['duel']['dueleeIndex']
        ];
        data['duel']['state'] = 'collection';
        data['duel']['tilePrizes'] = [3, 3];
      } else {
        data['log'].add(
            'Tie of ${data['duel']['duelerCard'][0]}, moving to joust #${data['duel']['joust']}');
        int joustNumber = data['duel']['joust'];
        data['duel']['oldJoustCards']['joust${joustNumber - 1}Dueler'] =
            data['duel']['duelerCard'];
        data['duel']['oldJoustCards']['joust${joustNumber - 1}Duelee'] =
            data['duel']['dueleeCard'];
        data['duel']['duelerCard'] = '';
        data['duel']['dueleeCard'] = '';
      }
    }
    // check if there is a siege ('1' and facevalue)
    else if (letterCardInvolved && oneCardInvolved) {
      print(
          'siege: dueler $duelerValue duelee $dueleeValue flipped $flipWinners');
      if (flipWinners) {
        // letter card owner wins
        if (dueleeValue == '1') {
          setWinner(data['duel']['duelerIndex'], data);
        } else {
          setWinner(data['duel']['dueleeIndex'], data);
        }
      } else {
        // one card owner wins
        if (dueleeValue == '1') {
          setWinner(data['duel']['dueleeIndex'], data);
        } else {
          setWinner(data['duel']['duelerIndex'], data);
        }
      }
      data['duel']['pillagePrize'] = 1 * data['duel']['joust'];
      data['duel']['tilePrizes'] = [0];
      data['duel']['state'] = 'collection';
    } else if (flipWinners) {
      print('flip winners');
      // winners are flipped, lower value wins
      if (stringToNumeric(duelerValue) > stringToNumeric(dueleeValue)) {
        setWinner(data['duel']['dueleeIndex'], data);
      } else {
        setWinner(data['duel']['duelerIndex'], data);
      }
      int tilePrize = (letterCardInvolved ? 2 : 1) * data['duel']['joust'];
      data['duel']['tilePrizes'] = [tilePrize];
      data['duel']['state'] = 'collection';
    } else {
      print('non flip winner');
      // winners are NOT flipped, higher value wins
      if (stringToNumeric(duelerValue) < stringToNumeric(dueleeValue)) {
        int responderIndex = data['duel']['dueleeIndex'];
        data['duel']['matcherIndex'] = data['duel']['duelerIndex'];
        data['duel']['responderIndex'] = responderIndex;
      } else {
        int matcherIndex = data['duel']['dueleeIndex'];
        data['duel']['matcherIndex'] = matcherIndex;
        data['duel']['responderIndex'] = data['duel']['duelerIndex'];
      }
      int tilePrize = (letterCardInvolved ? 2 : 1) * data['duel']['joust'];
      data['duel']['tilePrizes'] = [tilePrize];
      data['duel']['state'] = 'matching';
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  playCard(data, i, val) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);

    // check if player is involved

    if (data['duel']['state'] == 'collection') {
      // collection ---------
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Can\'t play during collection!'),
        duration: Duration(seconds: 3),
      ));
      return;
    } else if (data['duel']['state'] == 'matching') {
      // matching ---------
      if (data['duel']['matcherIndex'] != playerIndex) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Someone else is matching!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      // remaining difference
      var diff = (stringToNumeric(data['duel']['dueleeCard'][0]) -
              stringToNumeric(data['duel']['duelerCard'][0]))
          .abs();
      var matchingCardsSum = stringToNumeric(val[0]);
      data['duel']['matchingCards'].forEach((v) {
        matchingCardsSum += stringToNumeric(v[0]);
      });
      if (matchingCardsSum > diff) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Matching cards over limit!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['duel']['matchingCards'].add(val);
    } else if (data['duel']['state'] == 'peasantsResponse') {
      // response ---------
      if (data['duel']['responderIndex'] != playerIndex) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Someone else is responding!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      var responderIndex = data['duel']['responderIndex'];
      var cardVal = data['duel']['dueleeCard'];
      if (responderIndex == data['duel']['duelerIndex']) {
        cardVal = data['duel']['duelerCard'];
      }
      if (val[0] != cardVal[0]) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Must be a "${cardVal[0]}"!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['duel']['peasantCards'].add(val);
    } else if (playerIndex == data['duel']['duelerIndex']) {
      // duel ---------
      // player is dueler
      if (data['duel']['duelerCard'] != '') {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content:
              Text('Already played! Remove your played card to play another.'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['duel']['duelerCard'] = val;
      if (data['duel']['dueleeCard'] != '') {
        determineDuelWinner(data);
      }
    } else if (playerIndex == data['duel']['dueleeIndex']) {
      // duel ---------
      // player is duelee
      if (data['duel']['dueleeCard'] != '') {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content:
              Text('Already played! Remove your played card to play another.'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['duel']['dueleeCard'] = val;
      if (data['duel']['duelerCard'] != '') {
        determineDuelWinner(data);
      }
    } else {
      // player is not involved at all
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Not your turn!'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    data['player${playerIndex}Hand'].removeAt(i);

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getHand(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    List<Widget> cards = [];
    // angles: 5 cards -> -80, -40, 0, 40, 80
    // 4 cards -> -60, -20, 20, 60
    // var angles = [-pi / 5, -pi / 10, 0.0, pi / 10, pi / 5];
    // switch (cards.length) {
    //   case 1:
    //     angles = [0.0];
    //     break;
    //   case 2:
    //     angles = [pi / 3, pi / 3];
    //     break;
    //   case 3:
    //     angles = [-pi / 3, 0.0, pi / 3];
    //     break;
    //   case 4:
    //     angles = [-pi / 3, -pi / 6, pi / 6, pi / 3];
    //     break;
    // }
    data['player${playerIndex}Hand'].asMap().forEach((i, val) {
      var card = Card(
        value: val,
        size: 'medium',
        callback: () => playCard(data, i, val),
      );
      cards.add(
          Container(padding: EdgeInsets.fromLTRB(2, 0, 2, 0), child: card));
    });
    return Column(
      children: <Widget>[
        // RaisedGradientButton(
        //   child: Text(
        //     'Fill Hand',
        //     style: TextStyle(color: Colors.white),
        //   ),
        //   height: 35,
        //   width: 110,
        //   onPressed: () => fillHand(
        //     data: data,
        //     scaffoldKey: _scaffoldKey,
        //     userId: widget.userId,
        //     sessionId: widget.sessionId,
        //   ), // TODO: disable if during duel
        //   gradient: !playerInDuel(data, widget.userId)
        //       ? LinearGradient(
        //           colors: <Color>[
        //             Theme.of(context).primaryColor,
        //             Theme.of(context).accentColor,
        //           ],
        //         )
        //       : LinearGradient(
        //           colors: <Color>[
        //             Colors.grey[600],
        //             Colors.grey[400],
        //           ],
        //         ),
        // ),
        // SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: cards,
        ),
      ],
    );
  }

  bool playerIsDueler(data) {
    // determine if player is dueler or duelee
    var playerIndex = data['playerIds'].indexOf(widget.userId);

    bool playerIsDueler = false;
    if (playerIndex == data['duel']['duelerIndex']) {
      playerIsDueler = true;
    }
    return playerIsDueler;
  }

  getDuel(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // player not in duel
    bool playerNotInDuel = playerIndex != data['duel']['duelerIndex'] &&
        playerIndex != data['duel']['dueleeIndex'];
    var playerCardValue = playerIsDueler(data)
        ? data['duel']['duelerCard']
        : data['duel']['dueleeCard'];
    var oppositeCardValue = !playerIsDueler(data)
        ? data['duel']['duelerCard']
        : data['duel']['dueleeCard'];
    Widget joust1PlayerCard = Container();
    Widget joust1OppositeCard = Container();
    Widget joust2PlayerCard = Container();
    Widget joust2OppositeCard = Container();
    if (data['duel']['oldJoustCards'].containsKey('joust1Dueler')) {
      if (playerIsDueler(data)) {
        joust1PlayerCard = Card(
          value: data['duel']['oldJoustCards']['joust1Dueler'],
          size: 'small',
        );
        joust1OppositeCard = Card(
          value: data['duel']['oldJoustCards']['joust1Duelee'],
          size: 'small',
        );
      } else {
        joust1PlayerCard = Card(
          value: data['duel']['oldJoustCards']['joust1Duelee'],
          size: 'small',
        );
        joust1OppositeCard = Card(
          value: data['duel']['oldJoustCards']['joust1Dueler'],
          size: 'small',
        );
      }
    }
    if (data['duel']['oldJoustCards'].containsKey('joust2Dueler')) {
      if (playerIsDueler(data)) {
        joust2PlayerCard = Card(
          value: data['duel']['oldJoustCards']['joust2Dueler'],
          size: 'small',
        );
        joust2OppositeCard = Card(
          value: data['duel']['oldJoustCards']['joust2Duelee'],
          size: 'small',
        );
      } else {
        joust2PlayerCard = Card(
          value: data['duel']['oldJoustCards']['joust2Duelee'],
          size: 'small',
        );
        joust2OppositeCard = Card(
          value: data['duel']['oldJoustCards']['joust2Dueler'],
          size: 'small',
        );
      }
    }
    if (playerNotInDuel) {
      playerCardValue = data['duel']['dueleeCard'];
      oppositeCardValue = data['duel']['duelerCard'];
    }
    var screenWidth = MediaQuery.of(context).size.width;
    var width = screenWidth / 7;
    var height = width * 1.25;
    var oppositeCard = oppositeCardValue == ''
        ? Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'waiting...',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : playerNotInDuel
            ? Container(
                height: height,
                width: width,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).highlightColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'waiting...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            : playerCardValue == ''
                ? Card(faceDown: true)
                : Card(
                    value: oppositeCardValue,
                    size: 'medium',
                  );
    if (playerNotInDuel && oppositeCardValue != '') {
      if (data['duel']['duelerCard'] != '' &&
          data['duel']['dueleeCard'] != '') {
        oppositeCard = Card(
          value: oppositeCardValue,
          size: 'medium',
        );
      } else {
        oppositeCard = Card(
          faceDown: true,
        );
      }
    }
    var playerCard = playerCardValue == ''
        ? Container(
            height: height,
            width: width,
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                playerNotInDuel ? 'waiting...' : 'play a card!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : playerNotInDuel
            ? Container(
                height: height,
                width: width,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).highlightColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'waiting...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            : Card(
                value: playerCardValue,
                size: 'medium',
                callback: () => returnCard(data),
              );
    if (playerNotInDuel && playerCardValue != '') {
      if (data['duel']['duelerCard'] != '' &&
          data['duel']['dueleeCard'] != '') {
        playerCard = Card(
          value: playerCardValue,
          size: 'medium',
        );
      } else {
        playerCard = Card(
          faceDown: true,
        );
      }
    }
    return Container(
      width: 160,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              data['duel']['oldJoustCards'].containsKey('joust1Dueler')
                  ? Text(
                      'Joust 1',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    )
                  : Container(),
              SizedBox(height: 5),
              Opacity(
                opacity: 0.3,
                child: joust1OppositeCard,
              ),
              SizedBox(height: 5),
              Opacity(
                opacity: 0.3,
                child: joust1PlayerCard,
              ),
            ],
          ),
          SizedBox(
            width: 10,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              oppositeCard,
              SizedBox(height: 5),
              playerCard,
            ],
          ),
          SizedBox(
            width: 10,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              data['duel']['oldJoustCards'].containsKey('joust2Dueler')
                  ? Text(
                      'Joust 2',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    )
                  : Container(),
              SizedBox(height: 5),
              Opacity(
                opacity: 0.3,
                child: joust2OppositeCard,
              ),
              SizedBox(height: 5),
              Opacity(
                opacity: 0.3,
                child: joust2PlayerCard,
              ),
            ],
          ),
        ],
      ),
    );
  }

  addTile(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // should normally be zero but could be one for multiple winners
    var winnerIndex = data['duel']['winnerIndexes'].indexOf(playerIndex);
    if (data['duel']['tilePrizes'][winnerIndex] > 0) {
      data['duel']['tilePrizes'][winnerIndex] -= 1;
      String letter = generateRandomLetter();
      data['player${playerIndex}Tiles'].add(letter);
      String winner = playerNameFromIndex(playerIndex, data);
      data['log'].add('$winner collected a tile: "${letter.toUpperCase()}"');
    }
    // if all players have collected all rewards, move to next duel
    var remainingTiles = 0;
    data['duel']['tilePrizes'].forEach((v) {
      remainingTiles += v;
    });
    if (remainingTiles == 0) {
      cleanupDuel(data);
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  pillage(data) async {
    if (data['duel']['pillagePrize'] > 0) {
      // show dialog to pillage or draw tiles
      showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          List<int> possiblePlayerIndices = List<int>.generate(
              data['playerIds'].length, (int index) => index);
          var playerIndex = data['playerIds'].indexOf(widget.userId);
          possiblePlayerIndices.remove(playerIndex);
          return PillageDialog(
            data: data,
            possiblePlayerIndices: possiblePlayerIndices,
            sessionId: widget.sessionId,
            userId: widget.userId,
          );
        },
      );
    }
  }

  returnMatchingCard(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Hand'].add(data['duel']['matchingCards'].last);
    data['duel']['matchingCards'].removeLast();

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  returnPeasantCard(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Hand'].add(data['duel']['peasantCards'].last);
    data['duel']['peasantCards'].removeLast();

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  matchDuel(data) async {
    data['duel']['state'] = 'peasantsResponse';
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    String player = playerNameFromIndex(
      playerIndex,
      data,
    );
    data['log'].add('$player matches!');

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  peasantResponse(data) async {
    var response = data['duel']['peasantCards'].length;
    var responderId = data['playerIds'][data['duel']['responderIndex']];
    var responderName = data['playerNames'][responderId];
    if (response == 1) {
      data['log'].add('Peasant\'s Blockade by $responderName!');
      data['duel']['tilePrizes'] = [2 * data['duel']['joust']];
      data['duel']['pillagePrize'] = 0;
      data['duel']['winnerIndexes'] = [data['duel']['matcherIndex']];
    } else if (response == 2) {
      data['log'].add('Peasant\'s Reversal by $responderName!');
      data['duel']['tilePrizes'] = [0];
      data['duel']['pillagePrize'] = 1 * data['duel']['joust'];
      data['duel']['winnerIndexes'] = [data['duel']['responderIndex']];
    } else {
      data['log'].add('Peasant\'s Uprising by $responderName!');
      data['log'].add('$responderName wins a crown!');
      data['duel']['winnerIndexes'] = [data['duel']['responderIndex']];
      grabCrown(data);
      return;
    }
    data['duel']['state'] = 'collection';

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  concede(data) async {
    var dueleeValue = data['duel']['dueleeCard'][0];
    var duelerValue = data['duel']['duelerCard'][0];
    bool letterCardInvolved = ['K', 'Q', 'J'].contains(dueleeValue) ||
        ['K', 'Q', 'J'].contains(duelerValue);
    if (data['duel']['state'] == 'matching') {
      // matcher concedes, responder wins normal tiles
      data['duel']['state'] = 'collection';
      data['duel']['winnerIndexes'] = [data['duel']['responderIndex']];
      data['duel']['tilePrizes'] = [1 * data['duel']['joust']];
      if (letterCardInvolved) {
        data['duel']['tilePrizes'] = [2 * data['duel']['joust']];
      }
      data['duel']['pillagePrize'] = 0;
      String plural = data['duel']['tilePrizes'][0] <= 1 ? 'tile' : 'tiles';
      String winner = playerNameFromIndex(data['duel']['responderIndex'], data);
      data['log'].add('$winner wins ${data['duel']['tilePrizes'][0]} $plural!');
      // return matching cards to matcher
      var matcherIndex = data['duel']['matcherIndex'];
      data['duel']['matchingCards'].forEach((v) {
        data['player${matcherIndex}Hand'].add(v);
      });
      data['duel']['matchingCards'] = [];
    } else if (data['duel']['state'] == 'peasantsResponse') {
      // responder concedes, matcher wins a pillage
      data['duel']['state'] = 'collection';
      data['duel']['winnerIndexes'] = [data['duel']['matcherIndex']];
      data['duel']['tilePrizes'] = [0];
      data['duel']['pillagePrize'] = 1 * data['duel']['joust'];
      String plural = data['duel']['pillagePrize'] <= 1 ? 'time' : 'times';
      String winner = playerNameFromIndex(data['duel']['matcherIndex'], data);
      data['log']
          .add('$winner pillages ${data['duel']['pillagePrize']} $plural!');
      // return responding cards to responder
      var responderIndex = data['duel']['responderIndex'];
      data['duel']['peasantCards'].forEach((v) {
        data['player${responderIndex}Hand'].add(v);
      });
      data['duel']['peasantCards'] = [];
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  grabCrown(data) async {
    // get crown
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Crowns'] += 1;
    data['crownWinner'] = widget.userId;
    data['nextTargetWord'] = generateRandomWord(
        data['rules']['minWordLength'], data['rules']['maxWordLength']);
    // go to screen where crown-owners pick their letter
    data['state'] = 'roundEnd';

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  burnTiles(data) async {
    // burn selected tiles and add tiles worth their value
    var totalValue = 0;
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    selectedTiles.forEach((i, v) {
      if (v[0]) {
        data['player${playerIndex}Tiles'].remove(v[1]);
        totalValue += letterValues[v[1]];
      }
    });
    // clear selections
    setState(() {
      selectedTiles = {};
    });
    var tilesTransmogrified = totalValue ~/ 5;
    var newTiles = [];
    for (var i = 0; i < tilesTransmogrified; i++) {
      String randomTile = generateRandomLetter();
      newTiles.add(randomTile);
      data['player${playerIndex}Tiles'].add(randomTile);
    }
    // add to log
    String logString = '';
    if (newTiles.length == 1) {
      logString = newTiles[0].toUpperCase();
    } else {
      logString = newTiles[0].toUpperCase();
      for (int i = 1; i < newTiles.length; i++) {
        logString += ', ${newTiles[i].toUpperCase()}';
      }
    }
    var playerName = data['playerNames'][widget.userId];
    data['log'].add(
        '$playerName burned $totalValue pts for $tilesTransmogrified tiles: $logString');

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  showPlayersDialog(data) {
    List<Widget> players = [
      SizedBox(
        height: 25,
      )
    ];
    List playerIds = data['playerIds'];
    playerIds.forEach((v) {
      var playerIndex = data['playerIds'].indexOf(v);
      var playerName = data['playerNames'][v];
      players.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(playerName,
                style: TextStyle(
                  fontSize: 24,
                )),
            SizedBox(width: 10),
            getCrowns(playerIndex, data),
          ],
        ),
      );
      players.add(SizedBox(height: 8));
      players.add(
        getTiles(playerIndex, data),
      );
      players.add(SizedBox(height: 25));
    });
    showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Players:'),
            contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
            content: Container(
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: players,
                ),
              ),
            ),
            actions: <Widget>[
              Container(
                child: FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ),
            ],
          );
        });
  }

  getCollectionAction(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if (data['duel']['winnerIndexes'].contains(playerIndex)) {
      var winnerIndex = data['duel']['winnerIndexes'].indexOf(playerIndex);
      List<Widget> rowItems = [];
      if (data['duel']['tilePrizes'][winnerIndex] > 0) {
        String plural =
            data['duel']['tilePrizes'][winnerIndex] == 1 ? 'tile' : 'tiles';
        rowItems.add(
          RaisedGradientButton(
              child: Text(
                '${data['duel']['tilePrizes'][winnerIndex]} ' +
                    plural +
                    ' left!',
                style: TextStyle(fontSize: 18),
              ),
              height: 50,
              width: 120,
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).primaryColor,
                  Theme.of(context).accentColor,
                ],
              ),
              onPressed: () {
                addTile(data);
              }),
        );
      }
      if (data['duel']['pillagePrize'] > 0) {
        String plural =
            data['duel']['pillagePrize'] == 1 ? 'pillage' : 'pillages';
        rowItems.add(
          RaisedGradientButton(
              child: Text(
                '${data['duel']['pillagePrize']} ' + plural + ' left!',
                style: TextStyle(fontSize: 18),
              ),
              height: 50,
              width: 150,
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).primaryColor,
                  Theme.of(context).accentColor,
                ],
              ),
              onPressed: () {
                pillage(data);
              }),
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: rowItems,
      );
    }
  }

  getMatchingAction(data) {
    bool playerIsInDuel = playerInDuel(data, widget.userId);
    if (widget.userId == data['playerIds'][data['duel']['matcherIndex']]) {
      String sumStatus = '';
      var diff = (stringToNumeric(data['duel']['dueleeCard'][0]) -
              stringToNumeric(data['duel']['duelerCard'][0]))
          .abs();
      var sum = -1;
      if (data['duel']['matchingCards'].length > 0) {
        sum = int.parse(data['duel']['matchingCards'][0][0]);
      }
      if (data['duel']['matchingCards'].length > 1) {
        sum = 0;
        data['duel']['matchingCards'].forEach((v) {
          sum += stringToNumeric(v[0]);
        });
      }
      if (data['duel']['matchingCards'].length == 0) {
        sumStatus = 'Need $diff!';
      } else {
        if (sum == diff) {
          sumStatus = 'Nice!';
        } else {
          sumStatus = '${data['duel']['matchingCards'][0][0]} < $diff';
          sumStatus = '';
          int i = 0;
          while (i < data['duel']['matchingCards'].length) {
            sumStatus +=
                stringToNumeric(data['duel']['matchingCards'][i][0]).toString();
            i += 1;
            if (i < data['duel']['matchingCards'].length) {
              sumStatus += '+';
            }
          }
          sumStatus += ' = $sum\n(need $diff)';
          if (sum == diff) {
            sumStatus = 'Nice!';
          }
        }
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              data['duel']['matchingCards'].length == 0
                  ? Card(
                      empty: true,
                      size: 'small',
                    )
                  : Card(
                      value: data['duel']['matchingCards'].last,
                      size: 'small',
                      callback: () {
                        returnMatchingCard(data);
                      },
                    ),
              SizedBox(height: 5),
              Text(
                sumStatus,
                style: TextStyle(
                  fontSize: 12,
                ),
              )
            ],
          ),
          SizedBox(width: 10),
          playerIsInDuel
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedGradientButton(
                      child: Text(
                        'Match',
                        style: TextStyle(fontSize: 19),
                      ),
                      height: 40,
                      width: 110,
                      onPressed: sum == diff
                          ? () {
                              matchDuel(data);
                            }
                          : null,
                      gradient: LinearGradient(
                        colors: sum == diff
                            ? [
                                Theme.of(context).primaryColor,
                                Theme.of(context).accentColor,
                              ]
                            : [
                                Colors.grey[400],
                                Colors.grey[300],
                              ],
                      ),
                    ),
                    SizedBox(height: 8),
                    RaisedGradientButton(
                      child: Text(
                        'I can only bow',
                        style: TextStyle(fontSize: 12),
                      ),
                      height: 30,
                      width: 110,
                      onPressed: sum == diff
                          ? null
                          : () {
                              concede(data);
                            },
                      gradient: LinearGradient(
                        colors: sum == diff
                            ? [
                                Colors.grey[400],
                                Colors.grey[300],
                              ]
                            : [
                                Colors.red[700],
                                Colors.red[500],
                              ],
                      ),
                    ),
                  ],
                )
              : Container(),
        ],
      );
    }
  }

  getResponseAction(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    bool playerIsResponding = playerIndex == data['duel']['responderIndex'];
    bool canRespond = false;
    var responderIndex = data['duel']['responderIndex'];
    var cardVal = data['duel']['dueleeCard'];
    if (responderIndex == data['duel']['duelerIndex']) {
      cardVal = data['duel']['duelerCard'];
    }
    String statusText = 'Play a "${cardVal[0]}"';
    if (playerIndex != data['duel']['responderIndex']) {
      statusText = '';
    }
    if (data['duel']['peasantCards'].length >= 1) {
      canRespond = true;
      statusText = 'Peasant\'s\nBlockage !';
    }
    if (data['duel']['peasantCards'].length >= 2) {
      statusText = 'Peasant\'s\nReversal !!';
    }
    if (data['duel']['peasantCards'].length >= 3) {
      statusText = 'Peasant\'s\nUprising !!!';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            data['duel']['peasantCards'].length == 0
                ? Card(
                    empty: true,
                    size: 'small',
                  )
                : Card(
                    value: data['duel']['peasantCards'].last,
                    size: 'small',
                    callback: () {
                      returnPeasantCard(data);
                    },
                  ),
            SizedBox(height: 5),
            Text(
              statusText,
              style: TextStyle(
                fontSize: data['duel']['peasantCards'].length > 0 ? 10 : 12,
              ),
            )
          ],
        ),
        SizedBox(width: 10),
        playerIsResponding
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedGradientButton(
                    child: Text(
                      'Respond',
                      style: TextStyle(fontSize: 16),
                    ),
                    height: 40,
                    width: 100,
                    onPressed: canRespond
                        ? () {
                            peasantResponse(data);
                          }
                        : null,
                    gradient: LinearGradient(
                      colors: canRespond
                          ? [
                              Theme.of(context).primaryColor,
                              Theme.of(context).accentColor,
                            ]
                          : [
                              Colors.grey[400],
                              Colors.grey[300],
                            ],
                    ),
                  ),
                  SizedBox(height: 8),
                  RaisedGradientButton(
                    child: Text(
                      'I can only bow',
                      style: TextStyle(fontSize: 11),
                    ),
                    height: 30,
                    width: 100,
                    onPressed: canRespond
                        ? null
                        : () {
                            concede(data);
                          },
                    gradient: LinearGradient(
                      colors: canRespond
                          ? [
                              Colors.grey[400],
                              Colors.grey[300],
                            ]
                          : [
                              Colors.red[700],
                              Colors.red[500],
                            ],
                    ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }

  getAction(data) {
    Widget action = Container();
    if (data['duel']['state'] == 'collection') {
      action = getCollectionAction(data);
    } else if (data['duel']['state'] == 'matching') {
      action = getMatchingAction(data);
    } else if (data['duel']['state'] == 'peasantsResponse') {
      action = getResponseAction(data);
    } else {
      // no actions
      action = Container();
    }

    if (action == null) {
      action = Container();
    }

    // check if crown can be grabbed
    bool canGrab = false;
    var holyLetters = [];
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Tiles'].forEach((v) {
      if (data['targetWord'].contains(v) || v == ' ') {
        holyLetters.add(v);
      }
    });
    // convert target word to char frequency map
    Map targetWordCharCount = {};
    data['targetWord'].runes.forEach((v) {
      String char = String.fromCharCode(v);
      if (targetWordCharCount.containsKey(char)) {
        targetWordCharCount[char] += 1;
      } else {
        targetWordCharCount[char] = 1;
      }
    });
    // convert tiles to char frequency map
    Map tilesCharCount = {};
    holyLetters.forEach((v) {
      if (tilesCharCount.containsKey(v)) {
        tilesCharCount[v] += 1;
      } else {
        tilesCharCount[v] = 1;
      }
    });
    // iterate over tile map, reducing both maps
    tilesCharCount.forEach((i, v) {
      if (i != ' ') {
        while (targetWordCharCount[i] > 0 && tilesCharCount[i] > 0) {
          targetWordCharCount[i] -= 1;
          tilesCharCount[i] -= 1;
        }
      }
    });
    // if at the end the target word map is empty, allow grab
    // or, if the total remaining is less than ~/3 remaining tiles, allow grab
    var remainingTargetLetters = 0;
    targetWordCharCount.forEach((i, v) {
      remainingTargetLetters += v;
    });
    var remainingTiles = 0;
    tilesCharCount.forEach((i, v) {
      if (i != ' ') {
        remainingTiles += v;
      }
    });
    // if tile map contains grails, reduce remaining target letters by that many grails
    int numGrails = 0;
    if (tilesCharCount.containsKey(' ')) {
      numGrails += 1;
    }
    numGrails += remainingTiles ~/ 3;
    // targetWordCharCount.values.reduce((sum, element) => sum + element);
    if (remainingTargetLetters <= 0 || remainingTargetLetters <= numGrails) {
      canGrab = true;
    }

    // check if sufficent tiles are selected
    bool canBurn = false;
    var sumSelectedTilePoints = 0;
    selectedTiles.forEach((i, v) {
      if (v[0]) {
        // get tile
        var letter = v[1];
        // add point for value of tile
        sumSelectedTilePoints += letterValues[letter];
      }
    });
    if (sumSelectedTilePoints >= 5) {
      canBurn = true;
    }

    var totalValue = 0;
    selectedTiles.forEach((i, v) {
      if (v[0]) {
        totalValue += letterValues[v[1]];
      }
    });

    return Container(
      height: 100,
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).dialogBackgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          action,
          SizedBox(width: 20),
          // default actions to see other players stuff and win game
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedGradientButton(
                height: 25,
                width: 70,
                child: Text('Crown!'),
                onPressed: canGrab
                    ? () {
                        grabCrown(data);
                      }
                    : null,
                gradient: LinearGradient(
                  colors: canGrab
                      ? [
                          Colors.amber[800],
                          Colors.amber[600],
                        ]
                      : [
                          Colors.grey[400],
                          Colors.grey[300],
                        ],
                ),
              ),
              SizedBox(height: 5),
              RaisedGradientButton(
                height: 25,
                width: 70,
                child: Text(totalValue < 5 ? 'Burn!' : 'Burn! $totalValue'),
                onPressed: canBurn
                    ? () {
                        burnTiles(data);
                      }
                    : null,
                gradient: LinearGradient(
                  colors: canBurn
                      ? [
                          Colors.red,
                          Colors.orange,
                        ]
                      : [
                          Colors.grey[400],
                          Colors.grey[300],
                        ],
                ),
              ),
              SizedBox(height: 5),
              RaisedGradientButton(
                height: 25,
                width: 70,
                child: Text(
                  'Players',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                gradient: LinearGradient(colors: [
                  Colors.blue[400],
                  Colors.blue[200],
                ]),
                onPressed: () {
                  showPlayersDialog(data);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  toggleTile(val, i) async {
    setState(() {
      if (selectedTiles.containsKey(i)) {
        selectedTiles[i] = [!selectedTiles[i][0], val];
      } else {
        selectedTiles[i] = [true, val];
      }
    });
  }

  getTiles(playerIndex, data) {
    List<String> holyLetters = [];
    int grails = 0;
    List<Widget> holyTiles = [
      SizedBox(
        height: 34,
      ),
    ];
    List<Widget> nonHolyTiles = [
      SizedBox(
        height: 34,
      )
    ];
    data['player${playerIndex}Tiles'].asMap().forEach((i, v) {
      var selected = false;
      if (selectedTiles.containsKey(i)) {
        if (selectedTiles[i][0]) {
          selected = true;
        }
      }
      if (v == ' ') {
        grails += 1;
      } else if (data['targetWord'].contains(v)) {
        holyLetters.add(v);
      } else {
        nonHolyTiles.add(
          Tile(
            value: v,
            holy: false,
            selected: selected,
            callback: () {
              toggleTile(v, i);
            },
            empty: false,
          ),
        );
        nonHolyTiles.add(
          SizedBox(width: 5),
        );
      }
    });

    // organize holy tiles
    // create char frequency of holy tiles
    Map holyCharCount = {' ': grails};
    holyLetters.forEach((v) {
      if (holyCharCount.containsKey(v)) {
        holyCharCount[v] += 1;
      } else {
        holyCharCount[v] = 1;
      }
    });
    // fill in target letters, then fill in with any grails
    data['targetWord'].runes.forEach((v) {
      bool filled = false;
      String letter = String.fromCharCode(v);
      if (holyCharCount.containsKey(letter)) {
        if (holyCharCount[letter] > 0) {
          holyTiles.add(
            Tile(
              value: letter,
              holy: true,
              selected: false,
              empty: false,
            ),
          );
          holyTiles.add(
            SizedBox(width: 5),
          );
          holyCharCount[letter] -= 1;
          filled = true;
        }
      }
      if (!filled) {
        if (holyCharCount[' '] > 0) {
          holyTiles.add(
            Tile(
              value: ' ',
              holy: true,
              selected: false,
              empty: false,
            ),
          );
          holyTiles.add(
            SizedBox(width: 5),
          );
          holyCharCount[' '] -= 1;
          filled = true;
        }
      }
      if (!filled) {
        holyTiles.add(
          Tile(
            empty: true,
          ),
        );
        holyTiles.add(
          SizedBox(width: 5),
        );
      }
    });
    holyTiles.add(SizedBox(width: 20));
    // dump remaining holy letters
    holyCharCount.forEach((i, v) {
      for (int j = 0; j < v; j++) {
        holyTiles.add(
          Tile(
            value: i,
            holy: true,
            selected: false,
            empty: false,
          ),
        );
        holyTiles.add(
          SizedBox(width: 5),
        );
      }
    });

    holyTiles.add(
      SizedBox(
        height: 30,
      ),
    );
    nonHolyTiles.add(
      SizedBox(
        height: 30,
      ),
    );
    if (holyTiles.length > 0) {
      holyTiles.removeAt(holyTiles.length - 1);
    }
    if (nonHolyTiles.length > 0) {
      nonHolyTiles.removeAt(nonHolyTiles.length - 1);
    }
    return Column(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: holyTiles,
          ),
        ),
        SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: nonHolyTiles,
          ),
        ),
      ],
    );
  }

  getLeftStatus(data) {
    if (data['duel']['state'] == 'collection') {
      var playerIndex = data['playerIds'].indexOf(widget.userId);
      var plural = 'is';
      if (data['duel']['winnerIndexes'].length > 1) {
        plural = 'are';
      }

      if (data['duel']['winnerIndexes'].contains(playerIndex)) {
        return Text('Collect your winnings!');
      } else {
        var winners = '';
        data['duel']['winnerIndexes'].forEach((v) {
          if (winners == '') {
            winners += playerNameFromIndex(v, data);
          } else {
            winners += ', ' + playerNameFromIndex(v, data);
          }
        });
        return Column(
          children: <Widget>[
            Text(
              winners,
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 3),
            Text('$plural collecting their winnings!'),
          ],
        );
      }
    }
    // matching
    if (data['duel']['state'] == 'matching') {
      if (widget.userId == data['playerIds'][data['duel']['matcherIndex']]) {
        return Text('Can you match?');
      } else {
        String matcher =
            playerNameFromIndex(data['duel']['matcherIndex'], data);
        return Column(
          children: <Widget>[
            Text('Waiting to see if '),
            SizedBox(height: 3),
            Text(
              matcher,
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 3),
            Text('can match!'),
          ],
        );
      }
    }
    // peasants response
    if (data['duel']['state'] == 'peasantsResponse') {
      if (widget.userId == data['playerIds'][data['duel']['responderIndex']]) {
        return Text('Can you respond?');
      } else {
        String matcher =
            playerNameFromIndex(data['duel']['responderIndex'], data);
        return Column(
          children: <Widget>[
            Text('Waiting to see if '),
            SizedBox(height: 3),
            Text(
              matcher,
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 3),
            Text('can respond to the match!'),
          ],
        );
      }
    }
    // duel
    bool playerIsInDuel = playerInDuel(data, widget.userId);
    if (playerIsInDuel) {
      var opponent = data['playerIds'][data['duel']['duelerIndex']];
      if (playerIsDueler(data)) {
        opponent = data['playerIds'][data['duel']['dueleeIndex']];
      }
      if (data['duel']['dueleeCard'] == '' ||
          data['duel']['dueleeCard'] == '') {
        return Column(
          children: <Widget>[
            Text('You are dueling:'),
            SizedBox(height: 3),
            Text(
              data['playerNames'][opponent],
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      } else if (data['duel']['dueleeCard'] != '' &&
          data['duel']['dueleeCard'] != '') {
        return Column(
          children: <Widget>[
            Text('You are dueling:'),
            SizedBox(height: 3),
            Text(
              data['playerNames'][opponent],
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      }
    }
    // player is not in duel
    var duelerId = data['playerIds'][data['duel']['duelerIndex']];
    var duelerName = data['playerNames'][duelerId];
    var dueleeId = data['playerIds'][data['duel']['dueleeIndex']];
    var dueleeName = data['playerNames'][dueleeId];
    return Column(
      children: <Widget>[
        Text(
          duelerName,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 3),
        Text('is dueling'),
        SizedBox(height: 3),
        Text(
          dueleeName,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  getRightStatus(data) {
    List<Text> playerNamesTurn = [];
    data['playerIds'].asMap().forEach((i, v) {
      String playerName = data['playerNames'][v];
      bool playerInDuel = false;
      if (data['duel']['duelerIndex'] == i ||
          data['duel']['dueleeIndex'] == i) {
        playerInDuel = true;
        playerName = '> ' + playerName;
      } else {
        playerName = '    ' + playerName;
      }
      if (v == widget.userId) {
        playerName += ' (you)';
      }
      playerNamesTurn.add(
        Text(
          playerName,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 12,
            color:
                playerInDuel ? Theme.of(context).highlightColor : Colors.grey,
          ),
        ),
      );
    });
    return Column(
      children: <Widget>[
        // target word
        Text('Target Word:'),
        SizedBox(height: 3),
        Text(
          data['targetWord'].toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 10),
        // player names and arrow
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: playerNamesTurn,
        ),
        SizedBox(height: 10),
        // room code
        Text(
          'Room code:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          widget.roomCode,
          style: TextStyle(
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  getCenter(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // check if player is part of duel
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).highlightColor,
            ),
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).dialogBackgroundColor,
          ),
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(child: getLeftStatus(data)),
              SizedBox(height: 10),
              getDuel(data),
            ],
          ),
        ),
        SizedBox(width: 10),
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).highlightColor,
                ),
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).dialogBackgroundColor,
              ),
              padding: EdgeInsets.all(10),
              child: getRightStatus(data),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).highlightColor,
                ),
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).dialogBackgroundColor,
              ),
              padding: EdgeInsets.all(10),
              child: getCrowns(playerIndex, data),
            ),
          ],
        ),
      ],
    );
  }

  getCrowns(playerIndex, data) {
    var numCrowns = data['player${playerIndex}Crowns'];
    return Row(
      children: [
        Icon(
          MdiIcons.crown,
          color: numCrowns > 0 ? Colors.amber : Colors.grey.withAlpha(100),
        ),
        Icon(
          MdiIcons.crown,
          color: numCrowns > 1 ? Colors.amber : Colors.grey.withAlpha(100),
        ),
        Icon(
          MdiIcons.crown,
          color: numCrowns > 2 ? Colors.amber : Colors.grey.withAlpha(100),
        ),
      ],
    );
  }

  getGameboard(data) {
    if (!playerInDuel(data, widget.userId)) {
      fillHand(
        data: data,
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        sessionId: widget.sessionId,
      );
    }
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    return SafeArea(
      child: Container(
        height: height,
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            getLog(data, context, 260),
            SizedBox(height: 10),
            getCenter(data),
            SizedBox(height: 10),
            getAction(data),
            SizedBox(height: 10),
            getHand(data),
            SizedBox(height: 10),
            getTiles(playerIndex, data),
            widget.userId == data['leader']
                ? Column(
                    children: <Widget>[
                      SizedBox(height: 20),
                      EndGameButton(
                        sessionId: widget.sessionId,
                        height: 35,
                        width: 100,
                        gameName: 'Three Crowns',
                      ),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  startNextRound(data) async {
    // set target word to next target word
    data['targetWord'] = data['nextTargetWord'];
    // clear selectedTiles, tiles
    data['playerIds'].asMap().forEach((i, v) {
      data['player${i}Tiles'] = data['player${i}SelectedTiles'];
      data['player${i}SelectedTiles'] = [];
    });
    // clear board
    cleanupDuel(data);
    data['state'] = 'duel';
  }

  addStartTile(val, data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);

    // add selected tile
    data['player${playerIndex}SelectedTiles'].add(val);

    // check if all players are done adding tiles, if so completely clear board
    var totalRemainingTiles = 0;
    // add all crowns and subtract all tiles
    for (int i = 0; i < data['playerIds'].length; i++) {
      totalRemainingTiles += data['player${i}Crowns'];
      totalRemainingTiles -= data['player${i}SelectedTiles'].length;
    }
    if (totalRemainingTiles <= 0) {
      startNextRound(data);
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getRoundEnd(data) {
    // check if game is over, if so just display crowns for every person
    bool gameIsOver = false;
    for (int i = 0; i < data['playerIds'].length; i++) {
      if (data['player${i}Crowns'] == 3) {
        gameIsOver = true;
      }
    }

    Widget tilePicking = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Next round will start when\ncrown owners pick their tiles!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        SizedBox(width: 10),
        Icon(
          MdiIcons.arrowRight,
          size: 30,
        )
      ],
    );
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    var remainingTiles = data['player${playerIndex}Crowns'] -
        data['player${playerIndex}SelectedTiles'].length;
    List<Widget> possibleTiles = [];
    data['nextTargetWord'].runes.forEach((v) {
      possibleTiles.add(
        Tile(
          value: String.fromCharCode(v),
          holy: false,
          selected: false,
          callback: () {
            addStartTile(String.fromCharCode(v), data);
          },
          empty: false,
        ),
      );
      possibleTiles.add(
        SizedBox(width: 4),
      );
    });
    List<Widget> selectedTiles = [];
    data['player${playerIndex}SelectedTiles'].forEach((v) {
      selectedTiles.add(
        Tile(
          value: v,
          holy: false,
          selected: false,
          empty: false,
        ),
      );
    });
    String plural = remainingTiles == 1 ? 'tile' : 'tiles';
    if (data['player${playerIndex}Crowns'] > 0 &&
        data['player${playerIndex}SelectedTiles'].length <
            data['player${playerIndex}Crowns']) {
      tilePicking = Column(
        children: [
          Text(
            'Pick $remainingTiles more $plural!',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: possibleTiles,
          ),
          SizedBox(height: 10),
          Text('Selected tiles:'),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: selectedTiles,
          ),
        ],
      );
    }
    List<Widget> everyone = [];
    List playerIds = data['playerIds'];
    playerIds.forEach((v) {
      var playerIndex = data['playerIds'].indexOf(v);
      var playerName = data['playerNames'][v];
      List<Widget> crowns = [];
      for (int i = 0; i < data['player${playerIndex}Crowns']; i++) {
        crowns.add(
          Icon(
            MdiIcons.crown,
            color: Colors.amber,
          ),
        );
      }
      // fill grey crowns
      while (crowns.length < 3) {
        crowns.add(
          Icon(
            MdiIcons.crown,
            color: Colors.grey,
          ),
        );
      }
      everyone.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              playerName,
              style: TextStyle(
                fontSize: gameIsOver ? 30 : 20,
              ),
            ),
            SizedBox(width: 10),
            Row(children: crowns),
          ],
        ),
      );
      if (!gameIsOver) {
        everyone.add(SizedBox(height: 5));
        everyone.add(
          getTiles(playerIndex, data),
        );
      }
      everyone.add(SizedBox(height: 15));
    });

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 50),
          Text(
            data['playerNames'][data['crownWinner']],
            style: TextStyle(
              fontSize: 40,
              color: Colors.lightBlue,
            ),
          ),
          Text(
            gameIsOver ? 'wins the game!' : 'wins a crown!',
            style: TextStyle(
              fontSize: 30,
            ),
          ),
          SizedBox(height: gameIsOver ? 50 : 20),
          Column(children: everyone),
          gameIsOver
              ? Container()
              : Column(
                  children: [
                    SizedBox(height: 30),
                    Text(
                      'Next word is',
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      data['nextTargetWord'].toUpperCase(),
                      style: TextStyle(fontSize: 40, color: Colors.green),
                    ),
                    SizedBox(height: 30),
                    tilePicking,
                  ],
                ),
          widget.userId == data['leader']
              ? Column(
                  children: <Widget>[
                    SizedBox(height: 20),
                    EndGameButton(
                      sessionId: widget.sessionId,
                      height: 35,
                      width: 100,
                      gameName: 'Three Crowns',
                    ),
                  ],
                )
              : Container(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Three Crowns',
                ),
              ),
              body: Container(),
            );
          }
          // all data for all components
          DocumentSnapshot snapshotData = snapshot.data;
          var data = snapshotData.data;
          if (data == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Three Crowns',
                ),
              ),
              body: Container(),
            );
          }
          checkIfExit(data);
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(
                'Three Crowns',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    // HapticFeedback.heavyImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return ThreeCrownsScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: data['state'] == 'roundEnd'
                ? getRoundEnd(data)
                : getGameboard(data),
          );
        });
  }
}

class Card extends StatelessWidget {
  final String value;
  final String size;
  final double rotation;
  final Function callback;
  final bool faceDown;
  final bool empty;

  Card({
    this.value,
    this.size = 'medium',
    this.rotation,
    this.callback,
    this.faceDown = false,
    this.empty = false,
  });

  getIcon(size) {
    var suit = value[1];
    if (value.length == 3) {
      suit = value[2];
    }
    switch (suit) {
      case 'S':
        return Icon(
          MdiIcons.cardsSpade,
          // MdiIcons.fish,
          color: Colors.blue.withAlpha(230),
          size: size,
        );
        break;
      case 'H':
        return Icon(
          MdiIcons.cardsHeart,
          // MdiIcons.ladybug,
          color: Colors.red.withAlpha(230),
          size: size,
        );
        break;
      case 'C':
        return Icon(
          MdiIcons.cardsClub,
          // MdiIcons.alien,
          color: Colors.green.withAlpha(230),
          size: size,
        );
        break;
      case 'D':
        return Icon(
          MdiIcons.cardsDiamond,
          // MdiIcons.duck,
          color: Colors.amber.withAlpha(230),
          size: size,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    // medium defaults
    var width = screenWidth / 7;
    var height = width * 1.25;
    double fontSize = 40;
    double iconSize = 60;
    if (size == 'small') {
      height = 55;
      width = 40;
      fontSize = 36;
      iconSize = 50;
    }
    if (empty) {
      return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).highlightColor),
            borderRadius: BorderRadius.circular(10),
          ));
    }
    if (faceDown) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Container(
            height: height - 15,
            width: width - 15,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                MdiIcons.crown,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: callback,
      child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).highlightColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 1,
                top: 1,
                child: getIcon(
                  iconSize,
                ),
              ),
              Positioned(
                child: Text(
                  value[0],
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                  ),
                ),
                top: 3,
                left: 5,
              ),
              value[0] == '4' && size == 'medium'
                  ? Positioned(
                      child: Icon(
                        MdiIcons.autorenew,
                        size: 20,
                        color: Colors.black.withAlpha(100),
                      ),
                      bottom: 1,
                      right: 1,
                    )
                  : Container(),
              value[0] == '1' && size == 'medium'
                  ? Positioned(
                      child: Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.black.withAlpha(100),
                      ),
                      bottom: 1,
                      right: 1,
                    )
                  : Container(),
            ],
          )),
    );
  }
}

class PillageDialog extends StatefulWidget {
  final data;
  final List<int> possiblePlayerIndices;
  final sessionId;
  final userId;

  PillageDialog({
    this.data,
    this.possiblePlayerIndices,
    this.sessionId,
    this.userId,
  });

  @override
  _PillageDialogState createState() => _PillageDialogState();
}

class _PillageDialogState extends State<PillageDialog> {
  int selectedPlayerIndex;
  int selectedTileIndex;
  List<int> possibleTileIndices;

  @override
  void initState() {
    super.initState();
    selectedPlayerIndex = widget.possiblePlayerIndices[0];
    selectedTileIndex = -1;
    if (widget.data['player${selectedPlayerIndex}Tiles'].length > 0) {
      selectedTileIndex = 0;
    }
    possibleTileIndices = List<int>.generate(
        widget.data['player${selectedPlayerIndex}Tiles'].length,
        (int index) => index);
  }

  stealTiles() async {
    var tile =
        widget.data['player${selectedPlayerIndex}Tiles'][selectedTileIndex];
    // add tile to winner index
    var playerIndex = widget.data['playerIds'].indexOf(widget.userId);
    widget.data['player${playerIndex}Tiles'].add(tile);
    // remove tile from selectedPlayerIndex
    widget.data['player${selectedPlayerIndex}Tiles'].remove(tile);
    String winner = playerNameFromIndex(playerIndex, widget.data);
    String selected = playerNameFromIndex(selectedPlayerIndex, widget.data);
    widget.data['log']
        .add('$winner stole a ${tile.toUpperCase()} from $selected!');

    widget.data['duel']['pillagePrize'] -= 1;

    // if player has collected all rewards, move to next duel
    if (widget.data['duel']['pillagePrize'] == 0) {
      cleanupDuel(widget.data);
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Choose your spoils!'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<int>(
            isExpanded: true,
            value: selectedPlayerIndex,
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Theme.of(context).highlightColor),
            underline: Container(
              height: 2,
              color: Theme.of(context).highlightColor,
            ),
            onChanged: (int newValue) {
              setState(() {
                selectedPlayerIndex = newValue;
                possibleTileIndices = List<int>.generate(
                    widget.data['player${selectedPlayerIndex}Tiles'].length,
                    (int index) => index);
                if (widget.data['player${selectedPlayerIndex}Tiles'].length >
                    0) {
                  selectedTileIndex = 0;
                }
              });
            },
            items: widget.possiblePlayerIndices.map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(
                    widget.data['playerNames'][widget.data['playerIds'][value]],
                    style: TextStyle(
                      fontFamily: 'Balsamiq',
                      fontSize: 18,
                    )),
              );
            }).toList(),
          ),
          widget.data['player${selectedPlayerIndex}Tiles'].length > 0 &&
                  selectedTileIndex != -1
              ? DropdownButton<int>(
                  isExpanded: true,
                  value: selectedTileIndex,
                  iconSize: 24,
                  elevation: 16,
                  style: TextStyle(color: Theme.of(context).highlightColor),
                  underline: Container(
                    height: 2,
                    color: Theme.of(context).highlightColor,
                  ),
                  onChanged: (int newValue) async {
                    setState(() {
                      selectedTileIndex = newValue;
                    });
                  },
                  items: possibleTileIndices
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        widget.data['player${selectedPlayerIndex}Tiles'][value]
                            .toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Balsamiq',
                          fontSize: 18,
                        ),
                      ),
                    );
                  }).toList(),
                )
              : Text(
                  'Player has no tiles!',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
          SizedBox(height: 15),
        ],
      ),
      actions: <Widget>[
        widget.data['player${selectedPlayerIndex}Tiles'].length == 0 ||
                selectedTileIndex == -1
            ? Container()
            : RaisedGradientButton(
                onPressed: () {
                  stealTiles();
                  Navigator.of(context).pop();
                },
                height: 30,
                width: 100,
                child: Text(
                  'Steal Tile!',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                gradient: LinearGradient(
                  colors: <Color>[
                    Color.fromARGB(255, 255, 185, 0),
                    Color.fromARGB(255, 255, 213, 0),
                  ],
                ),
              ),
        RaisedGradientButton(
          onPressed: () async {
            // get two tiles
            var playerIndex = widget.data['playerIds'].indexOf(widget.userId);
            String winner = playerNameFromIndex(playerIndex, widget.data);
            String letter1 = generateRandomLetter();
            String letter2 = generateRandomLetter();
            widget.data['player${playerIndex}Tiles'].add(letter1);
            widget.data['player${playerIndex}Tiles'].add(letter2);
            widget.data['log'].add(
                '$winner collected two tiles: "${letter1.toUpperCase()}" and "${letter2.toUpperCase()}"');
            widget.data['duel']['pillagePrize'] -= 1;
            // if player has collected all rewards, move to next duel
            if (widget.data['duel']['pillagePrize'] == 0) {
              cleanupDuel(widget.data);
            }

            await Firestore.instance
                .collection('sessions')
                .document(widget.sessionId)
                .setData(widget.data);

            Navigator.of(context).pop();
          },
          child: Text('2 Tiles!'),
          height: 30,
          width: 80,
          gradient: LinearGradient(
            colors: <Color>[
              Colors.green[600],
              Colors.green[400],
            ],
          ),
        ),
      ],
    );
  }
}

class Tile extends StatelessWidget {
  final String value;
  final bool holy;
  final Function callback;
  final bool selected;
  final bool empty;

  Tile({this.value, this.holy, this.callback, this.selected, this.empty});

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
          color: Colors.grey,
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        if (callback != null) {
          callback();
        }
      },
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.green : Colors.grey,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(5),
          gradient: LinearGradient(
            colors: holy
                ? [
                    Colors.purple[500],
                    Colors.pink[300],
                  ]
                : [
                    Colors.grey[800],
                    Colors.grey[600],
                  ],
          ),
        ),
        child: Container(
          // decoration: BoxDecoration(border: Border.all()),
          child: Stack(
            children: [
              Positioned(
                top: selected ? 2 : 3,
                left: selected ? 4 : 5,
                child: Text(
                  value.toUpperCase(),
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: selected ? 1 : 2,
                right: selected ? 2 : 3,
                child: Text(
                  letterValues[value].toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
