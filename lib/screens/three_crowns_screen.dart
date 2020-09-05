import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:together/services/services.dart';
import 'package:together/services/three_crowns_services.dart';
import 'template/help_screen.dart';
import 'lobby_screen.dart';

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

  checkIfExit(data) async {
    // run async func to check if game is over, or back to lobby or deleted (main menu)
    if (data == null) {
      print('game was deleted');

      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      print('moving to lobby');
      // reset first team to green
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .updateData({'turn': 'green'});

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

  stringToNumeric(String v) {
    if (v == 'C') {
      return 8;
    }
    if (v == 'B') {
      return 9;
    }
    if (v == 'A') {
      return 10;
    }
    return int.parse(v);
  }

  cleanupDuel(data) async {
    data['duel']['dueleeCard'] = '';
    data['duel']['duelerCard'] = '';
    data['duel']['matchingCards'] = [];
    data['duel']['peasantCards'] = [];
    data['duel']['joust'] = 1;
    data['duel']['tilePrize'] = 0;
    data['duel']['pillagePrize'] = 0;
    // next duel
    data['duel']['duelerIndex'] += 1;
    if (data['duel']['duelerIndex'] >= data['playerIds'].length) {
      data['duel']['duelerIndex'] = 0;
    }
    data['duel']['state'] = 'duel';
  }

  showLog(data) {
    var latestLog = data['log'].last;
    var secondLatestLog = data['log'][data['log'].length - 2];
    var thirdLatestLog = data['log'][data['log'].length - 3];

    List<Widget> fullLogs = [];
    data['log'].sublist(3).reversed.forEach((v) {
      fullLogs.add(
        Text(
          v,
          style: TextStyle(
            fontSize: v.startsWith('Now') && v.endsWith('turn') ? 14 : 16,
            color: v.startsWith('Now') && v.endsWith('turn')
                ? Colors.grey
                : Colors.white,
          ),
        ),
      );
    });

    return Container(
      width: 240,
      height: 70,
      child: RaisedButton(
        onPressed: () {
          showDialog<Null>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Logs:'),
                contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                content: Container(
                  height: 200,
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 10),
                      Container(
                        height: 190,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).highlightColor),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.all(10),
                          child: SingleChildScrollView(
                            child: Column(
                              children: fullLogs,
                            ),
                          ),
                        ),
                      ),
                    ],
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
            },
          );
        },
        shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Colors.white),
            borderRadius: BorderRadius.circular(5.0)),
        padding: const EdgeInsets.all(0.0),
        child: Container(
          constraints: BoxConstraints(),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.grey[900]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 3),
              Text(
                '-   ' + latestLog + '   -',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3),
              Text(
                secondLatestLog,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[200],
                ),
              ),
              SizedBox(height: 3),
              Text(
                thirdLatestLog,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 3),
              Text(
                '(click to show full logs)',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }

  playerNameFromIndex(int index, data) {
    var playerId = data['playerIds'][index];
    return data['playerNames'][playerId];
  }

  setWinner(winnerIndex, data) {
    if (winnerIndex >= data['playerIds'].length) {
      winnerIndex = 0;
    }
    data['duel']['winnerIndex'] = winnerIndex;
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
    bool letterCardInvolved = ['A', 'B', 'C'].contains(dueleeValue) ||
        ['A', 'B', 'C'].contains(duelerValue);
    bool oneCardInvolved = dueleeValue == '1' || duelerValue == '1';

    // if there is a value tie, immediately move to next joust
    if (duelerValue == dueleeValue) {
      print('joust');
      data['duel']['joust'] += 1;
      data['log'].add(
          'Tie of ${data['duel']['duelerCard'][0]}, moving to joust #${data['duel']['joust']}');
      if (data['duel']['joust'] == 4) {
        data['log'].add('Three jousts complete! Both players get three tiles.');
        data['duel']['state'] = 'collection';
        data['duel']['tilePrize'] = 3;
      }
    }
    // check if there is a siege ('1' and facevalue)
    else if (letterCardInvolved && oneCardInvolved) {
      print('seige');
      if (flipWinners) {
        // letter card owner wins
        if (dueleeValue == '1') {
          setWinner(data['duel']['duelerIndex'], data);
        } else {
          setWinner(data['duel']['duelerIndex'] + 1, data);
        }
      } else {
        // one card owner wins
        if (dueleeValue == '1') {
          setWinner(data['duel']['duelerIndex'] + 1, data);
        } else {
          setWinner(data['duel']['duelerIndex'], data);
        }
      }
      data['duel']['pillagePrize'] = 1 * data['duel']['joust'];
      data['duel']['state'] = 'collection';
    } else if (flipWinners) {
      print('flip winners');
      // winners are flipped, lower value wins
      if (stringToNumeric(duelerValue) > stringToNumeric(dueleeValue)) {
        setWinner(data['duel']['duelerIndex'] + 1, data);
      } else {
        setWinner(data['duel']['duelerIndex'], data);
      }
      int tilePrize = (letterCardInvolved ? 2 : 1) * data['duel']['joust'];
      data['duel']['tilePrize'] = tilePrize;
      data['duel']['state'] = 'collection';
    } else {
      print('non flip winner');
      // winners are NOT flipped, higher value wins
      if (stringToNumeric(duelerValue) < stringToNumeric(dueleeValue)) {
        int responderIndex = data['duel']['duelerIndex'];
        responderIndex = data['duel']['duelerIndex'] + 1;
        if (responderIndex >= data['playerIds'].length) {
          responderIndex = 0;
        }
        data['duel']['matcherIndex'] = data['duel']['duelerIndex'];
        data['duel']['responderIndex'] = responderIndex;
      } else {
        int matcherIndex = data['duel']['duelerIndex'] + 1;
        if (matcherIndex >= data['playerIds'].length) {
          matcherIndex = 0;
        }
        data['duel']['matcherIndex'] = matcherIndex;
        data['duel']['responderIndex'] = data['duel']['duelerIndex'];
      }
      int tilePrize = (letterCardInvolved ? 2 : 1) * data['duel']['joust'];
      data['duel']['tilePrize'] = tilePrize;
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
      if (diff < matchingCardsSum) {
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
    } else {
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
        RaisedGradientButton(
          child: Text(
            'Fill Hand',
            style: TextStyle(color: Colors.white),
          ),
          height: 35,
          width: 110,
          onPressed: () => fillHand(
            data: data,
            scaffoldKey: _scaffoldKey,
            userId: widget.userId,
            sessionId: widget.sessionId,
          ), // TODO: disable if during duel
          gradient: !playerInDuel(data, widget.userId)
              ? LinearGradient(
                  colors: <Color>[
                    Theme.of(context).primaryColor,
                    Theme.of(context).accentColor,
                  ],
                )
              : LinearGradient(
                  colors: <Color>[
                    Colors.grey[600],
                    Colors.grey[400],
                  ],
                ),
        ),
        SizedBox(height: 15),
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

  getPlayerInDuel(data) {
    var playerCardValue = playerIsDueler(data)
        ? data['duel']['duelerCard']
        : data['duel']['dueleeCard'];
    var oppositeCardValue = !playerIsDueler(data)
        ? data['duel']['duelerCard']
        : data['duel']['dueleeCard'];
    var oppositeCard = oppositeCardValue == ''
        ? Container(
            height: 80,
            width: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'waiting...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : playerCardValue == ''
            ? Card(
                faceDown: true,
              )
            : Card(
                value: oppositeCardValue,
                size: 'medium',
              );
    var playerCard = playerCardValue == ''
        ? Container(
            height: 80,
            width: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'play a card!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
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
    return Container(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          oppositeCard,
          SizedBox(height: 5),
          playerCard,
        ],
      ),
    );
  }

  getPlayerWaitingForDuel(data) {
    // TODO: improve lol
    return Text('Waiting for duel...');
  }

  getStatus(data) {
    // collections
    if (data['duel']['state'] == 'collection') {
      if (widget.userId == data['playerIds'][data['duel']['winnerIndex']]) {
        return Text('Collect your winnings!');
      } else {
        String winner = playerNameFromIndex(data['duel']['winnerIndex'], data);
        return Column(
          children: <Widget>[
            Text(
              winner,
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 3),
            Text('is collecting their winnings!'),
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
        return Text('Can you match?');
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
        opponent = data['playerIds'][data['duel']['duelerIndex'] + 1];
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
    return getPlayerWaitingForDuel(data);
  }

  addTile(data) async {
    if (data['duel']['tilePrize'] > 0) {
      data['duel']['tilePrize'] -= 1;
      int winnerIndex = data['duel']['winnerIndex'];
      data['player${winnerIndex}Tiles'].add(generateRandomLetter());
      String winner = playerNameFromIndex(data['duel']['winnerIndex'], data);
      data['log'].add('$winner collected a tile');
    }
    // if player has collected all rewards, move to next duel
    if (data['duel']['tilePrize'] == 0) {
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
          var playerIndex = data['playerIds'].indexOf(widget.userId);
          List<int> possiblePlayerIndices = List<int>.generate(
              data['playerIds'].length, (int index) => index);
          possiblePlayerIndices.remove(playerIndex);
          int selectedPlayerIndex = possiblePlayerIndices[0];
          int selectedTileIndex = -1;
          if (data['player${selectedPlayerIndex}Tiles'].length > 0) {
            selectedTileIndex = data['player${selectedPlayerIndex}Tiles'][0];
          }
          print('working with $possiblePlayerIndices');
          fljsdkfjf
          // have to figure out how to filter tiles for the selected player
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
                      print('setting to $newValue');
                      selectedPlayerIndex = newValue;
                    });
                  },
                  items: possiblePlayerIndices
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(data['playerNames'][data['playerIds'][value]],
                          style: TextStyle(
                            fontFamily: 'Balsamiq',
                            fontSize: 18,
                          )),
                    );
                  }).toList(),
                ),
                data['player${selectedPlayerIndex}Tiles'].length > 0
                    ? DropdownButton<int>(
                        isExpanded: true,
                        value: selectedTileIndex,
                        iconSize: 24,
                        elevation: 16,
                        style:
                            TextStyle(color: Theme.of(context).highlightColor),
                        underline: Container(
                          height: 2,
                          color: Theme.of(context).highlightColor,
                        ),
                        onChanged: (int newValue) {
                          selectedTileIndex = newValue;
                        },
                        items: data['player${selectedPlayerIndex}Tiles']
                            .map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                                data['player${selectedPlayerIndex}Tiles']
                                    [selectedTileIndex],
                                style: TextStyle(
                                  fontFamily: 'Balsamiq',
                                  fontSize: 18,
                                )),
                          );
                        }).toList(),
                      )
                    : Container(),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('cancel'),
              ),
              RaisedGradientButton(
                onPressed: () {
                  // ensure that tile is selected
                  data['duel']['pillagePrize'] -= 1;
                  Navigator.of(context).pop();
                },
                height: 30,
                width: 100,
                child: Text('Steal Tile!'),
                gradient: LinearGradient(
                  colors: <Color>[
                    Color.fromARGB(255, 255, 185, 0),
                    Color.fromARGB(255, 255, 213, 0),
                  ],
                ),
              ),
              RaisedGradientButton(
                onPressed: () {
                  // steal tile
                  int winnerIndex = data['duel']['winnerIndex'];
                  String winner =
                      playerNameFromIndex(data['duel']['winnerIndex'], data);
                  data['player${winnerIndex}Tiles'].add(generateRandomLetter());
                  data['player${winnerIndex}Tiles'].add(generateRandomLetter());
                  data['log'].add('$winner collected two tiles!');
                  data['duel']['pillagePrize'] -= 1;
                  Navigator.of(context).pop();
                },
                child: Text('2 Tiles!'),
                height: 30,
                width: 100,
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.green[500],
                    Colors.green[300],
                  ],
                ),
              ),
            ],
          );
        },
      );
    }
    // if player has collected all rewards, move to next duel
    if (data['duel']['pillagePrize'] == 0) {
      cleanupDuel(data);
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
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

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  addCrown(winnerId, data) async {
    data['player${winnerId}Crowns'] += 1;
    if (data['player${winnerId}Crowns'] >= 3) {
      // end game
      print('will end game');
      // data['state'] = 'complete';
    }

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
      data['duel']['tilePrize'] = 2 * data['duel']['joust'];
      data['duel']['winnerIndex'] = data['duel']['matcherIndex'];
    } else if (response == 2) {
      data['log'].add('Peasant\'s Reversal by $responderName!');
      data['duel']['pillagePrize'] = 2 * data['duel']['joust'];
      data['duel']['winnerIndex'] = data['duel']['responderIndex'];
    } else {
      data['log'].add('Peasant\'s Uprising by $responderName!');
      data['log'].add('$responderName wins a crown!');
      addCrown(responderId, data);
      data['duel']['winnerIndex'] = data['duel']['responderIndex'];
      return;
    }
    data['duel']['state'] = 'collection';

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getAction(data) {
    Widget action = Container();
    if (data['duel']['state'] == 'collection') {
      if (widget.userId == data['playerIds'][data['duel']['winnerIndex']]) {
        List<Widget> rowItems = [];
        if (data['duel']['tilePrize'] > 0) {
          String plural = data['duel']['tilePrize'] == 1 ? 'tile' : 'tiles';
          rowItems.add(
            RaisedGradientButton(
                child: Text(
                  '${data['duel']['tilePrize']} ' + plural + ' left!',
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
        action = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowItems,
        );
      }
    } else if (data['duel']['state'] == 'matching') {
      if (widget.userId == data['playerIds'][data['duel']['matcherIndex']]) {
        String sumStatus = '';
        var diff = (stringToNumeric(data['duel']['dueleeCard'][0]) -
                stringToNumeric(data['duel']['duelerCard'][0]))
            .abs();
        var sum = -1;
        if (data['duel']['matchingCards'].length == 0) {
          sumStatus = 'Need $diff more!';
        } else if (data['duel']['matchingCards'].length == 1) {
          if (data['duel']['matchingCards'][0][0] == diff) {
            sumStatus = 'Nice!';
          } else {
            sumStatus = '${data['duel']['matchingCards'][0][0]} < $diff';
          }
        } else {
          int i = 0;
          while (i < data['duel']['matchingCards'].length) {
            sumStatus +=
                stringToNumeric(data['duel']['matchingCards'][i][0]).toString();
            i += 1;
            if (i < data['duel']['matchingCards'].length) {
              sumStatus += ' + ';
            }
          }
          sum = data['duel']['matchingCards']
              .reduce((a, b) => stringToNumeric(a[0]) + stringToNumeric(b[0]));
          sumStatus += ' = $sum (need $diff)';
          if (sum == diff) {
            sumStatus = 'Nice!';
          }
        }
        action = Row(
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
            Column(
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
                  onPressed: () {
                    print('will concede');
                  },
                  gradient: LinearGradient(
                    colors: [
                      Colors.red[700],
                      Colors.red[500],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }
    } else if (data['duel']['state'] == 'peasantsResponse') {
      bool canRespond = false;
      var responderIndex = data['duel']['responderIndex'];
      var cardVal = data['duel']['dueleeCard'];
      if (responderIndex == data['duel']['duelerIndex']) {
        cardVal = data['duel']['duelerCard'];
      }
      String statusText = 'Play a "${cardVal[0]}"';
      if (data['duel']['peasantCards'].length >= 1) {
        canRespond = true;
        statusText = 'Peasant\'s Blockage !';
      }
      if (data['duel']['peasantCards'].length >= 2) {
        statusText = 'Peasant\'s Reversal !!';
      }
      if (data['duel']['peasantCards'].length >= 3) {
        statusText = 'Peasant\'s Uprising !!!';
      }
      action = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  fontSize: 12,
                ),
              )
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedGradientButton(
                child: Text(
                  'Respond',
                  style: TextStyle(fontSize: 17),
                ),
                height: 40,
                width: 110,
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
                  style: TextStyle(fontSize: 12),
                ),
                height: 30,
                width: 110,
                onPressed: () {
                  print('will concede');
                },
                gradient: LinearGradient(
                  colors: [
                    Colors.red[700],
                    Colors.red[500],
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      action = Text('no actions');
    }
    return Container(
      height: 100,
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: action,
    );
  }

  getCenter(data) {
    // check if player is part of duel
    return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).highlightColor,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(child: getStatus(data)),
            SizedBox(height: 20),
            playerInDuel(data, widget.userId)
                ? getPlayerInDuel(data)
                : getPlayerWaitingForDuel(data),
          ],
        ));
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
    return SafeArea(
      child: Container(
        height: height,
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            showLog(data),
            SizedBox(height: 20),
            getCenter(data),
            SizedBox(height: 20),
            getAction(data),
            SizedBox(height: 20),
            getHand(data),
            widget.userId == data['leader']
                ? Column(
                    children: <Widget>[
                      SizedBox(height: 30),
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
                body: Container());
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
                body: Container());
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
            body: getGameboard(data),
          );
        });
  }
}

class ThreeCrownsScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Bananaphone: Rules',
      information: ['    rules here'],
      buttonColor: Theme.of(context).primaryColor,
    );
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
          // MdiIcons.cardsSpade,
          MdiIcons.fish,
          color: Colors.blue,
          size: size,
        );
        break;
      case 'H':
        return Icon(
          // MdiIcons.cardsHeart,
          MdiIcons.ladybug,
          color: Colors.red,
          size: size,
        );
        break;
      case 'C':
        return Icon(
          // MdiIcons.cardsClub,
          MdiIcons.alien,
          color: Colors.green,
          size: size,
        );
        break;
      case 'D':
        return Icon(
          // MdiIcons.cardsDiamond,
          MdiIcons.duck,
          color: Colors.amber,
          size: size,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = 80;
    double width = 60;
    double fontSize = 24;
    if (size == 'small') {
      height = 55;
      width = 40;
      fontSize = 18;
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                value[0],
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                ),
              ),
              getIcon(
                fontSize,
              ),
            ],
          )),
    );
  }
}
