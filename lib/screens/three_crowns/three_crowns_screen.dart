import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/services.dart';

import 'package:together/services/services.dart';
import 'package:together/services/firestore.dart';
import 'package:together/screens/three_crowns/three_crowns_services.dart';
import 'package:together/screens/three_crowns/three_crowns_components.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/log.dart';
import 'package:together/components/end_game.dart';
import 'package:together/components/scroll_view.dart';

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
  var currDuelerIndex = 0;
  var currDueleeIndex = 1;
  var currDuelPhase = 'duel';
  var T;

  @override
  void initState() {
    super.initState();
    T = Transactor(sessionId: widget.sessionId);
  }

  checkIfVibrate(data) {
    // turn
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if (currDuelerIndex != data['duelerIndex']) {
      currDuelerIndex = data['duelerIndex'];
      currDueleeIndex = data['dueleeIndex'];
      if ([currDuelerIndex, currDueleeIndex].contains(playerIndex)) {
        HapticFeedback.vibrate();
        HapticFeedback.vibrate();
      } else {
        HapticFeedback.vibrate();
      }
    }

    // phase
    if (currDuelPhase != data['phase']) {
      currDuelPhase = data['phase'];
      HapticFeedback.vibrate();
    }
  }

  returnCard(data) async {
    // check if both cards are played, if so show snackbar (duel already started!)
    if (data['duelerCard'] != '' && data['dueleeCard'] != '') {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Duel has already started!'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if (playerIndex == data['duelerIndex']) {
      // player is dueler
      data['player${playerIndex}Hand'].add(data['duelerCard']);
      data['duelerCard'] = '';
    } else {
      data['player${playerIndex}Hand'].add(data['dueleeCard']);
      data['dueleeCard'] = '';
    }

    HapticFeedback.heavyImpact();

    T.transact(data);
  }

  setWinner(winnerIndex, data) {
    data['winnerIndexes'] = [winnerIndex];
    var name = playerNameFromIndex(winnerIndex, data);
    if (winnerIndex == data['duelerIndex']) {
      data['log']
          .add('$name wins: ${data['duelerCard']} beats ${data['dueleeCard']}');
    } else {
      data['log']
          .add('$name wins: ${data['dueleeCard']} beats ${data['duelerCard']}');
    }
  }

  addBonusTiles(data) {
    String duelerValue = data['duelerCard'][0];
    String dueleeValue = data['dueleeCard'][0];

    bool fiveSixSevenPair = true;
    if (!['5', '6', '7'].contains(dueleeValue)) {
      fiveSixSevenPair = false;
    }
    if (!['5', '6', '7'].contains(duelerValue)) {
      fiveSixSevenPair = false;
    }
    if (dueleeValue == duelerValue) {
      fiveSixSevenPair = false;
    }
    if (fiveSixSevenPair) {
      data['log']
          .add('$dueleeValue and $duelerValue! Both players get 1 bonus tile.');
      data['phase'] = 'collection';
      if (data['winnerIndexes'][0] == data['duelerIndex']) {
        data['tilePrizes'] = [1 + data['tilePrizes'][0], 1];
      } else {
        data['tilePrizes'] = [1, 1 + data['tilePrizes'][0]];
      }
      data['winnerIndexes'] = [data['duelerIndex'], data['dueleeIndex']];
    }
  }

  determineDuelWinner(data) async {
    print('determining winner');

    // set up values
    bool flipWinners = false;
    String duelerValue = data['duelerCard'][0];
    String duelerSuit = data['duelerCard'][1];
    String dueleeValue = data['dueleeCard'][0];
    String dueleeSuit = data['dueleeCard'][1];
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
      data['joust'] += 1;
      if (data['joust'] >= 4) {
        data['log'].add('Three jousts! Both players get 3 tiles.');
        data['winnerIndexes'] = [data['duelerIndex'], data['dueleeIndex']];
        data['phase'] = 'collection';
        data['tilePrizes'] = [3, 3];
      } else {
        data['log'].add(
            'Tie of ${data['duelerCard'][0]}, moving to joust #${data['joust']}');
        int joustNumber = data['joust'];
        data['oldJoustCards']['joust${joustNumber - 1}Dueler'] =
            data['duelerCard'];
        data['oldJoustCards']['joust${joustNumber - 1}Duelee'] =
            data['dueleeCard'];
        data['duelerCard'] = '';
        data['dueleeCard'] = '';
      }
    }
    // check if there is a siege ('1' and facevalue)
    else if (letterCardInvolved && oneCardInvolved) {
      print(
          'siege: dueler $duelerValue duelee $dueleeValue flipped $flipWinners');
      if (flipWinners) {
        // letter card owner wins
        if (dueleeValue == '1') {
          setWinner(data['duelerIndex'], data);
        } else {
          setWinner(data['dueleeIndex'], data);
        }
      } else {
        // one card owner wins
        if (dueleeValue == '1') {
          setWinner(data['dueleeIndex'], data);
        } else {
          setWinner(data['duelerIndex'], data);
        }
      }
      data['pillagePrize'] = 1 * data['joust'];
      data['tilePrizes'] = [0];
      data['phase'] = 'collection';
    } else if (flipWinners) {
      print('flip winners');
      // winners are flipped, lower value wins
      var winner = data['duelerIndex'];
      if (stringToNumeric(duelerValue) > stringToNumeric(dueleeValue)) {
        winner = data['dueleeIndex'];
      }
      setWinner(winner, data);
      int tilePrize = (letterCardInvolved ? 2 : 1) * data['joust'];
      data['tilePrizes'] = [tilePrize];
      data['phase'] = 'collection';
      addBonusTiles(data);
    } else {
      print('non flip winner');
      // winners are NOT flipped, higher value wins
      if (stringToNumeric(duelerValue) < stringToNumeric(dueleeValue)) {
        int responderIndex = data['dueleeIndex'];
        data['matcherIndex'] = data['duelerIndex'];
        data['responderIndex'] = responderIndex;
      } else {
        int matcherIndex = data['dueleeIndex'];
        data['matcherIndex'] = matcherIndex;
        data['responderIndex'] = data['duelerIndex'];
      }
      int tilePrize = (letterCardInvolved ? 2 : 1) * data['joust'];
      data['tilePrizes'] = [tilePrize];
      data['phase'] = 'matching';
    }

    T.transact(data);
  }

  playCard(data, i, val) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);

    // check if player is involved

    if (data['phase'] == 'collection') {
      // collection ---------
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Can\'t play during collection!'),
        duration: Duration(seconds: 3),
      ));
      return;
    } else if (data['phase'] == 'matching') {
      // matching ---------
      if (data['matcherIndex'] != playerIndex) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Someone else is matching!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      // remaining difference
      var diff = (stringToNumeric(data['dueleeCard'][0]) -
              stringToNumeric(data['duelerCard'][0]))
          .abs();
      var matchingCardsSum = stringToNumeric(val[0]);
      data['matchingCards'].forEach((v) {
        matchingCardsSum += stringToNumeric(v[0]);
      });
      if (matchingCardsSum > diff) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Matching cards over limit!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['matchingCards'].add(val);
    } else if (data['phase'] == 'peasantsResponse') {
      // response ---------
      if (data['responderIndex'] != playerIndex) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Someone else is responding!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      var responderIndex = data['responderIndex'];
      var cardVal = data['dueleeCard'];
      if (responderIndex == data['duelerIndex']) {
        cardVal = data['duelerCard'];
      }
      if (val[0] != cardVal[0]) {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Must be a "${cardVal[0]}"!'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['peasantCards'].add(val);
    } else if (playerIndex == data['duelerIndex']) {
      // duel ---------
      // player is dueler
      if (data['duelerCard'] != '') {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content:
              Text('Already played! Remove your played card to play another.'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['duelerCard'] = val;

      data = await T.transactThreeCrownsDuelerCard(val, playerIndex, i);

      if (data['dueleeCard'] != '') {
        determineDuelWinner(data);
      }
    } else if (playerIndex == data['dueleeIndex']) {
      if (data['dueleeCard'] != '') {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content:
              Text('Already played! Remove your played card to play another.'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      data['dueleeCard'] = val;

      data = await T.transactThreeCrownsDueleeCard(val, playerIndex, i);

      if (data['duelerCard'] != '') {
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

    HapticFeedback.heavyImpact();

    T.transact(data);
  }

  getHand(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    List<Widget> cards = [];
    data['player${playerIndex}Hand'].asMap().forEach((i, val) {
      var card = ThreeCrownsCard(
        value: val,
        size: 'medium',
        callback: () => playCard(data, i, val),
      );
      cards.add(
          Container(padding: EdgeInsets.fromLTRB(2, 0, 2, 0), child: card));
    });
    return Column(
      children: <Widget>[
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
    if (playerIndex == data['duelerIndex']) {
      playerIsDueler = true;
    }
    return playerIsDueler;
  }

  getDuel(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // player not in duel
    bool playerNotInDuel = playerIndex != data['duelerIndex'] &&
        playerIndex != data['dueleeIndex'];
    var playerCardValue =
        playerIsDueler(data) ? data['duelerCard'] : data['dueleeCard'];
    var oppositeCardValue =
        !playerIsDueler(data) ? data['duelerCard'] : data['dueleeCard'];
    Widget joust1PlayerCard = Container();
    Widget joust1OppositeCard = Container();
    Widget joust2PlayerCard = Container();
    Widget joust2OppositeCard = Container();
    if (data['oldJoustCards'].containsKey('joust1Dueler')) {
      if (playerIsDueler(data)) {
        joust1PlayerCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust1Dueler'],
          size: 'small',
        );
        joust1OppositeCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust1Duelee'],
          size: 'small',
        );
      } else {
        joust1PlayerCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust1Duelee'],
          size: 'small',
        );
        joust1OppositeCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust1Dueler'],
          size: 'small',
        );
      }
    }
    if (data['oldJoustCards'].containsKey('joust2Dueler')) {
      if (playerIsDueler(data)) {
        joust2PlayerCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust2Dueler'],
          size: 'small',
        );
        joust2OppositeCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust2Duelee'],
          size: 'small',
        );
      } else {
        joust2PlayerCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust2Duelee'],
          size: 'small',
        );
        joust2OppositeCard = ThreeCrownsCard(
          value: data['oldJoustCards']['joust2Dueler'],
          size: 'small',
        );
      }
    }
    if (playerNotInDuel) {
      playerCardValue = data['dueleeCard'];
      oppositeCardValue = data['duelerCard'];
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
                ? ThreeCrownsCard(faceDown: true)
                : ThreeCrownsCard(
                    value: oppositeCardValue,
                    size: 'medium',
                  );
    if (playerNotInDuel && oppositeCardValue != '') {
      if (data['duelerCard'] != '' && data['dueleeCard'] != '') {
        oppositeCard = ThreeCrownsCard(
          value: oppositeCardValue,
          size: 'medium',
        );
      } else {
        oppositeCard = ThreeCrownsCard(
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
            : ThreeCrownsCard(
                value: playerCardValue,
                size: 'medium',
                callback: () => returnCard(data),
              );
    if (playerNotInDuel && playerCardValue != '') {
      if (data['duelerCard'] != '' && data['dueleeCard'] != '') {
        playerCard = ThreeCrownsCard(
          value: playerCardValue,
          size: 'medium',
        );
      } else {
        playerCard = ThreeCrownsCard(
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
              data['oldJoustCards'].containsKey('joust1Dueler')
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
              data['oldJoustCards'].containsKey('joust2Dueler')
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
    var winnerIndex = data['winnerIndexes'].indexOf(playerIndex);
    if (data['tilePrizes'][winnerIndex] > 0) {
      data['tilePrizes'][winnerIndex] -= 1;
      String letter = generateRandomLetter();
      data['player${playerIndex}Tiles'].add(letter);
      String winner = playerNameFromIndex(playerIndex, data);
      data['log'].add('$winner collected a tile: "${letter.toUpperCase()}"');
    }
    // if all players have collected all rewards, move to next duel
    var remainingTiles = 0;
    data['tilePrizes'].forEach((v) {
      remainingTiles += v;
    });
    if (remainingTiles == 0) {
      cleanupDuel(data);
    }

    T.transact(data);
  }

  pillage(data) async {
    if (data['pillagePrize'] > 0) {
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
    data['player${playerIndex}Hand'].add(data['matchingCards'].last);
    data['matchingCards'].removeLast();

    T.transact(data);
  }

  returnPeasantCard(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Hand'].add(data['peasantCards'].last);
    data['peasantCards'].removeLast();

    T.transact(data);
  }

  matchDuel(data) async {
    data['phase'] = 'peasantsResponse';
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    String player = playerNameFromIndex(
      playerIndex,
      data,
    );
    data['log'].add('$player matches!');

    T.transact(data);
  }

  peasantResponse(data) async {
    var response = data['peasantCards'].length;
    var responderId = data['playerIds'][data['responderIndex']];
    var responderName = data['playerNames'][responderId];
    if (response == 1) {
      data['log'].add('Peasant\'s Blockade by $responderName!');
      data['tilePrizes'] = [2 * data['joust']];
      data['pillagePrize'] = 0;
      data['winnerIndexes'] = [data['matcherIndex']];
    } else if (response == 2) {
      data['log'].add('Peasant\'s Reversal by $responderName!');
      data['tilePrizes'] = [0];
      data['pillagePrize'] = 1 * data['joust'];
      data['winnerIndexes'] = [data['responderIndex']];
    } else {
      data['log'].add('Peasant\'s Uprising by $responderName!');
      data['log'].add('$responderName wins a crown!');
      data['winnerIndexes'] = [data['responderIndex']];
      grabCrown(data);
      return;
    }
    data['phase'] = 'collection';

    T.transact(data);
  }

  concede(data) async {
    var dueleeValue = data['dueleeCard'][0];
    var duelerValue = data['duelerCard'][0];
    bool letterCardInvolved = ['K', 'Q', 'J'].contains(dueleeValue) ||
        ['K', 'Q', 'J'].contains(duelerValue);
    if (data['phase'] == 'matching') {
      // matcher concedes, responder wins normal tiles
      data['phase'] = 'collection';
      data['winnerIndexes'] = [data['responderIndex']];
      data['tilePrizes'] = [1 * data['joust']];
      if (letterCardInvolved) {
        data['tilePrizes'] = [2 * data['joust']];
      }
      addBonusTiles(data);
      data['pillagePrize'] = 0;
      String plural = data['tilePrizes'][0] <= 1 ? 'tile' : 'tiles';
      String winner = playerNameFromIndex(data['responderIndex'], data);
      data['log'].add('$winner wins ${data['tilePrizes'][0]} $plural!');
      // return matching cards to matcher
      var matcherIndex = data['matcherIndex'];
      data['matchingCards'].forEach((v) {
        data['player${matcherIndex}Hand'].add(v);
      });
      data['matchingCards'] = [];
    } else if (data['phase'] == 'peasantsResponse') {
      // responder concedes, matcher wins a pillage
      data['phase'] = 'collection';
      data['winnerIndexes'] = [data['matcherIndex']];
      data['tilePrizes'] = [0];
      data['pillagePrize'] = 1 * data['joust'];
      String plural = data['pillagePrize'] <= 1 ? 'time' : 'times';
      String winner = playerNameFromIndex(data['matcherIndex'], data);
      data['log'].add('$winner pillages ${data['pillagePrize']} $plural!');
      // return responding cards to responder
      var responderIndex = data['responderIndex'];
      data['peasantCards'].forEach((v) {
        data['player${responderIndex}Hand'].add(v);
      });
      data['peasantCards'] = [];
    }

    T.transact(data);
  }

  grabCrown(data) async {
    // get crown
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Crowns'] += 1;
    data['crownWinner'] = widget.userId;
    data['nextTargetWord'] = generateRandomWord(
        data['rules']['minWordLength'], data['rules']['maxWordLength']);
    // go to screen where crown-owners pick their letter
    data['phase'] = 'roundEnd';

    HapticFeedback.heavyImpact();

    // check if game is over, if so increment player score
    if (data['player${playerIndex}Crowns'] == 3) {
      incrementPlayerScore('threeCrowns', data['playerIds'][playerIndex]);
    }

    T.transact(data);
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

    HapticFeedback.heavyImpact();

    T.transact(data);
  }

  showPlayersDialog(data) {
    HapticFeedback.heavyImpact();
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
              child: TogetherScrollView(
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
    if (data['winnerIndexes'].contains(playerIndex)) {
      var winnerIndex = data['winnerIndexes'].indexOf(playerIndex);
      List<Widget> rowItems = [];
      if (data['tilePrizes'][winnerIndex] > 0) {
        String plural = data['tilePrizes'][winnerIndex] == 1 ? 'tile' : 'tiles';
        rowItems.add(
          RaisedGradientButton(
              child: Text(
                '${data['tilePrizes'][winnerIndex]} ' + plural + ' left!',
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
      if (data['pillagePrize'] > 0) {
        String plural = data['pillagePrize'] == 1 ? 'pillage' : 'pillages';
        rowItems.add(
          RaisedGradientButton(
              child: Text(
                '${data['pillagePrize']} ' + plural + ' left!',
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
    if (widget.userId == data['playerIds'][data['matcherIndex']]) {
      String sumStatus = '';
      var diff = (stringToNumeric(data['dueleeCard'][0]) -
              stringToNumeric(data['duelerCard'][0]))
          .abs();
      var sum = -1;
      if (data['matchingCards'].length > 0) {
        sum = int.parse(data['matchingCards'][0][0]);
      }
      if (data['matchingCards'].length > 1) {
        sum = 0;
        data['matchingCards'].forEach((v) {
          sum += stringToNumeric(v[0]);
        });
      }
      if (data['matchingCards'].length == 0) {
        sumStatus = 'Need $diff!';
      } else {
        if (sum == diff) {
          sumStatus = 'Nice!';
        } else {
          sumStatus = '${data['matchingCards'][0][0]} < $diff';
          sumStatus = '';
          int i = 0;
          while (i < data['matchingCards'].length) {
            sumStatus +=
                stringToNumeric(data['matchingCards'][i][0]).toString();
            i += 1;
            if (i < data['matchingCards'].length) {
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
              data['matchingCards'].length == 0
                  ? ThreeCrownsCard(
                      empty: true,
                      size: 'small',
                    )
                  : ThreeCrownsCard(
                      value: data['matchingCards'].last,
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
    bool playerIsResponding = playerIndex == data['responderIndex'];
    bool canRespond = false;
    var responderIndex = data['responderIndex'];
    var cardVal = data['dueleeCard'];
    if (responderIndex == data['duelerIndex']) {
      cardVal = data['duelerCard'];
    }
    String statusText = 'Play a "${cardVal[0]}"';
    if (playerIndex != data['responderIndex']) {
      statusText = '';
    }
    if (data['peasantCards'].length >= 1) {
      canRespond = true;
      statusText = 'Peasant\'s\nBlockage !';
    }
    if (data['peasantCards'].length >= 2) {
      statusText = 'Peasant\'s\nReversal !!';
    }
    if (data['peasantCards'].length >= 3) {
      statusText = 'Peasant\'s\nUprising !!!';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            data['peasantCards'].length == 0
                ? ThreeCrownsCard(
                    empty: true,
                    size: 'small',
                  )
                : ThreeCrownsCard(
                    value: data['peasantCards'].last,
                    size: 'small',
                    callback: () {
                      returnPeasantCard(data);
                    },
                  ),
            SizedBox(height: 5),
            Text(
              statusText,
              style: TextStyle(
                fontSize: data['peasantCards'].length > 0 ? 10 : 12,
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
    if (data['phase'] == 'collection') {
      action = getCollectionAction(data);
    } else if (data['phase'] == 'matching') {
      action = getMatchingAction(data);
    } else if (data['phase'] == 'peasantsResponse') {
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
    HapticFeedback.heavyImpact();
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
    if (data['phase'] == 'collection') {
      var playerIndex = data['playerIds'].indexOf(widget.userId);
      var plural = 'is';
      if (data['winnerIndexes'].length > 1) {
        plural = 'are';
      }

      if (data['winnerIndexes'].contains(playerIndex)) {
        return Text('Collect your winnings!');
      } else {
        var winners = '';
        data['winnerIndexes'].forEach((v) {
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
    if (data['phase'] == 'matching') {
      if (widget.userId == data['playerIds'][data['matcherIndex']]) {
        return Text('Can you match?');
      } else {
        String matcher = playerNameFromIndex(data['matcherIndex'], data);
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
    if (data['phase'] == 'peasantsResponse') {
      if (widget.userId == data['playerIds'][data['responderIndex']]) {
        return Text('Can you respond?');
      } else {
        String matcher = playerNameFromIndex(data['responderIndex'], data);
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
      var opponent = data['playerIds'][data['duelerIndex']];
      if (playerIsDueler(data)) {
        opponent = data['playerIds'][data['dueleeIndex']];
      }
      if (data['dueleeCard'] == '' || data['dueleeCard'] == '') {
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
      } else if (data['dueleeCard'] != '' && data['dueleeCard'] != '') {
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
    var duelerId = data['playerIds'][data['duelerIndex']];
    var duelerName = data['playerNames'][duelerId];
    var dueleeId = data['playerIds'][data['dueleeIndex']];
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
      if (data['duelerIndex'] == i || data['dueleeIndex'] == i) {
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
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    return SafeArea(
      child: TogetherScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 40),
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
    data['phase'] = 'duel';
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

    T.transact(data);
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

    return TogetherScrollView(
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
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
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
          var data = snapshotData.data();
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
          checkIfExit(data, context, widget.sessionId, widget.roomCode);
          checkIfVibrate(data);
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
                    HapticFeedback.heavyImpact();
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
            body: data['phase'] == 'roundEnd'
                ? getRoundEnd(data)
                : getGameboard(data),
          );
        });
  }
}
