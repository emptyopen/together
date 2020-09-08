import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:together/services/services.dart';
import 'package:together/components/buttons.dart';
import 'template/help_screen.dart';
import 'lobby_screen.dart';
import 'package:together/components/misc.dart';

class RiversScreen extends StatefulWidget {
  RiversScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _RiversScreenState createState() => _RiversScreenState();
}

class _RiversScreenState extends State<RiversScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int clickedHandCard = -1;
  var currPlayer = '';
  bool isSpectator = false;

  @override
  void initState() {
    super.initState();
    setUpGame();
  }

  checkIfExit(data) async {
    // run async func to check if game is over, or back to lobby or deleted (main menu)
    if (data == null) {
      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
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

  checkIfVibrate(data) {
    if (currPlayer != data['turn']) {
      currPlayer = data['turn'];
      if (currPlayer == widget.userId) {
        HapticFeedback.vibrate();
      }
    }
  }

  setUpGame() async {
    // get session info for locations
    var data = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    setState(() {
      isSpectator = data['spectatorIds'].contains(widget.userId);
    });
  }

  getHand(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    var playerHand = data['player${playerIndex}Hand'];
    List<Widget> cards = [
      SizedBox(
        width: 5,
      )
    ];
    playerHand.forEach((v) {
      cards.add(
        RiversCard(
          value: v.toString(),
          clickable: false,
          clicked: clickedHandCard == v,
          isCenter: false,
          numCards: data['rules']['handSize'],
          callback: () {
            setState(() {
              if (clickedHandCard == v) {
                clickedHandCard = -1;
              } else {
                clickedHandCard = v;
              }
            });
          },
        ),
      );
      cards.add(
        SizedBox(width: 5),
      );
    });
    return Column(
      children: <Widget>[
        Text('YOUR HAND'),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: cards,
        ),
      ],
    );
  }

  drawCard(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // check if card can be drawn
    if (data['player${playerIndex}Hand'].length >= data['rules']['handSize']) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Hand is full!'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    if (widget.userId == data['turn']) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Can\'t draw during your turn!'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    // add card to hand
    data['player${playerIndex}Hand'].add(data['drawPile'].last);
    // remove card from draw pile
    data['drawPile'].remove(data['drawPile'].last);

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getDrawPile(data) {
    var drawPile = RiversCard(
      empty: true,
      isCenter: true,
    );
    if (data['drawPile'].length > 0) {
      drawPile = RiversCard(
        flipped: true,
        callback: () => drawCard(data),
        isCenter: true,
      );
    }
    return Column(children: <Widget>[
      Text('DRAW PILE'),
      Text(
        '(${data['drawPile'].length} remaining)',
        style: TextStyle(
          fontSize: 10,
        ),
      ),
      SizedBox(height: 10),
      drawPile
    ]);
  }

  cardIsValidForPile(data, pileName, value) {
    var topCard = data[pileName].last;
    // no card selected
    if (value == -1) {
      return false;
    }
    // descending
    if (pileName.contains('descend')) {
      if (value < topCard || value == topCard + 10) {
        return true;
      }
      return false;
    }
    // ascending
    else {
      if (value > topCard || value == topCard - 10) {
        return true;
      }
      return false;
    }
  }

  endTurn(data) async {
    var missingCards = 0;
    data['playerIds'].asMap().forEach((i, v) {
      missingCards += data['rules']['handSize'] - data['player${i}Hand'].length;
    });
    if (data['drawPile'].length - missingCards <= 0) {
      data['cardsToPlay'] = 1;
    } else {
      data['cardsToPlay'] = 2;
    }

    var currentTurnIndex = data['playerIds'].indexOf(data['turn']);
    var nextTurnIndex = currentTurnIndex + 1;
    if (nextTurnIndex == data['playerIds'].length) {
      nextTurnIndex = 0;
    }
    // skip until find player with cards
    var attempts = 0; // shouldn't need this but just in case
    while (data['player${nextTurnIndex}Hand'].length == 0) {
      attempts += 1;
      if (attempts > 150) {
        break;
      }
      nextTurnIndex = currentTurnIndex + 1;
      if (nextTurnIndex == data['playerIds'].length) {
        nextTurnIndex = 0;
      }
      data['turn'] = data['playerIds'][nextTurnIndex];
    }
    // update turn
    data['turn'] = data['playerIds'][nextTurnIndex];

    // log end of turn
    logEvent(data, 'Now ${data['playerNames'][data['turn']]}\'s turn');

    // if next turn player's hand is not full, fill it
    while (
        data['player${nextTurnIndex}Hand'].length < data['rules']['handSize']) {
      data['player${nextTurnIndex}Hand'].add(data['drawPile'].last);
      data['drawPile'].remove(data['drawPile'].last);
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  playCard(data, pileName, cardToAdd) async {
    // check if it's player's turn
    if (widget.userId != data['turn']) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Not your turn!'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    // add card to pile
    data[pileName].add(cardToAdd);
    // remove card from hand
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Hand'].remove(cardToAdd);
    // set selected card to nil
    setState(() {
      clickedHandCard = -1;
    });
    // log played card
    var playerName = data['playerNames'][widget.userId];
    HapticFeedback.vibrate();
    logEvent(data, '$playerName played $cardToAdd');

    // check if required cards are played
    if (data['cardsToPlay'] > 0) {
      data['cardsToPlay'] -= 1;
    }

    // if draw pile and everyone's hand is empty, end the game
    var remainingCards = data['drawPile'].length;
    if (remainingCards == 0) {
      data['playerIds'].asMap().forEach((i, v) {
        remainingCards += data['player${i}Hand'].length;
      });
      if (remainingCards == 0) {
        endGame(data);
      }
    } else {
      // if hand is empty, automatically end turn
      if (data['player${playerIndex}Hand'].length == 0) {
        endTurn(data);
      }
    }

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getAscendPiles(data) {
    bool ascend1Clickable = false;
    bool ascend2Clickable = false;
    bool ascend1ExtraClickable = false;
    bool ascend2ExtraClickable = false;
    // if hand card is selected and conditions are valid, highlight it
    if (clickedHandCard != -1) {
      if (clickedHandCard > data['ascendPile1'].last) {
        ascend1Clickable = true;
      }
      if (clickedHandCard == data['ascendPile1'].last - 10) {
        ascend1ExtraClickable = true;
      }
      if (clickedHandCard > data['ascendPile2'].last) {
        ascend2Clickable = true;
      }
      if (clickedHandCard == data['ascendPile2'].last - 10) {
        ascend2ExtraClickable = true;
      }
    }
    return Column(
      children: <Widget>[
        Text('ASCENDING'),
        SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              MdiIcons.chevronDoubleUp,
              size: 70,
            ),
            SizedBox(width: 10),
            RiversCard(
              value: data['ascendPile1'].last.toString(),
              clickable: ascend1Clickable,
              extraClickable: ascend1ExtraClickable,
              isCenter: true,
              callback: () {
                if (clickedHandCard == -1) {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('No card selected!'),
                    duration: Duration(seconds: 2),
                  ));
                } else if (cardIsValidForPile(
                    data, 'ascendPile1', clickedHandCard)) {
                  playCard(
                    data,
                    'ascendPile1',
                    clickedHandCard,
                  );
                } else {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('Not a valid pile!'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
            ),
            SizedBox(width: 40),
            RiversCard(
              value: data['ascendPile2'].last.toString(),
              clickable: ascend2Clickable,
              extraClickable: ascend2ExtraClickable,
              isCenter: true,
              callback: () {
                if (clickedHandCard == -1) {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('No card selected!'),
                    duration: Duration(seconds: 2),
                  ));
                } else if (cardIsValidForPile(
                    data, 'ascendPile2', clickedHandCard)) {
                  playCard(
                    data,
                    'ascendPile2',
                    clickedHandCard,
                  );
                } else {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('Not a valid pile!'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
            ),
            SizedBox(width: 10),
            Icon(
              MdiIcons.chevronDoubleUp,
              size: 70,
            ),
          ],
        ),
      ],
    );
  }

  getDescendPiles(data) {
    bool descend1Clickable = false;
    bool descend2Clickable = false;
    bool descend1ExtraClickable = false;
    bool descend2ExtraClickable = false;
    // if hand card is selected and conditions are valid, highlight it
    if (clickedHandCard != -1) {
      if (clickedHandCard < data['descendPile1'].last) {
        descend1Clickable = true;
      }
      if (clickedHandCard == data['descendPile1'].last + 10) {
        descend1ExtraClickable = true;
      }
      if (clickedHandCard < data['descendPile2'].last) {
        descend2Clickable = true;
      }
      if (clickedHandCard == data['descendPile2'].last + 10) {
        descend2ExtraClickable = true;
      }
    }
    return Column(
      children: <Widget>[
        Text('DESCENDING'),
        SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              MdiIcons.chevronDoubleDown,
              size: 70,
            ),
            SizedBox(width: 10),
            RiversCard(
              value: data['descendPile1'].last.toString(),
              clickable: descend1Clickable,
              extraClickable: descend1ExtraClickable,
              isCenter: true,
              callback: () {
                if (clickedHandCard == -1) {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('No card selected!'),
                    duration: Duration(seconds: 2),
                  ));
                } else if (cardIsValidForPile(
                    data, 'descendPile1', clickedHandCard)) {
                  playCard(
                    data,
                    'descendPile1',
                    clickedHandCard,
                  );
                } else {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('Not a valid pile!'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
            ),
            SizedBox(width: 40),
            RiversCard(
              value: data['descendPile2'].last.toString(),
              clickable: descend2Clickable,
              extraClickable: descend2ExtraClickable,
              isCenter: true,
              callback: () {
                if (clickedHandCard == -1) {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('No card selected!'),
                    duration: Duration(seconds: 2),
                  ));
                } else if (cardIsValidForPile(
                    data, 'descendPile2', clickedHandCard)) {
                  playCard(
                    data,
                    'descendPile2',
                    clickedHandCard,
                  );
                } else {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text('Not a valid pile!'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
            ),
            SizedBox(width: 10),
            Icon(
              MdiIcons.chevronDoubleDown,
              size: 70,
            ),
          ],
        ),
      ],
    );
  }

  getCenterCards(data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        getAscendPiles(data),
        SizedBox(height: 10),
        getDescendPiles(data),
      ],
    );
  }

  getStatus(data) {
    var currentPlayerName = data['playerNames'][data['turn']];
    Text currentTurn = Text('It is $currentPlayerName\'s turn:',
        style: TextStyle(
          color: Colors.white,
        ));
    if (widget.userId == data['turn']) {
      currentTurn = Text(
        'It is your turn:',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 18,
        ),
      );
    }
    List<Widget> statusItems = [
      currentTurn,
      data['cardsToPlay'] > 0
          ? Text(
              'Must play\n${data['cardsToPlay']} more cards!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )
          : Text(
              'Play more cards\nor end turn!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
      SizedBox(height: 5),
      PageBreak(
        width: 20,
        color: Colors.grey,
      ),
    ];
    data['playerIds'].forEach((v) {
      String name = data['playerNames'][v];
      if (widget.userId == v) {
        name = name + ' (you)';
      }
      statusItems.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          v == data['turn']
              ? Text(
                  '> ',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor, fontSize: 12),
                )
              : Container(),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: v == data['turn'] ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ));
    });
    return Container(
      width: 150,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: statusItems,
      ),
    );
  }

  getEndTurnButton(data) {
    return RaisedGradientButton(
      onPressed: () => endTurn(data),
      child: Text('End my turn'),
      height: 30,
      width: 120,
      gradient: LinearGradient(
        colors: <Color>[
          Theme.of(context).primaryColor,
          Theme.of(context).accentColor,
        ],
      ),
    );
  }

  endGame(data) async {
    // count cards in deck and players' hands
    var score = data['drawPile'].length;
    data['playerIds'].asMap().forEach((i, v) {
      score += data['player${i}Hand'].length;
    });
    data['finalScore'] = score;
    // move to post game screen with score
    data['state'] = 'complete';

    // if score is zero, increment player scores for game mode
    for (int i = 0; i < data['playerIds'].length; i++) {
      incrementPlayerScore(
          'rivers${data['rules']['handSize']}', data['playerIds'][i]);
    }

    // print('will update data with: $data');

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getGiveUpButton(data) {
    return RaisedGradientButton(
      onPressed: () {
        showDialog<Null>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Give up confirmation'),
              contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                FlatButton(
                  onPressed: () {
                    endGame(data);
                    Navigator.of(context).pop();
                  },
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
      child: Text('Give up'),
      height: 30,
      width: 80,
      gradient: LinearGradient(
        colors: <Color>[
          Colors.red,
          Colors.red[300],
        ],
      ),
    );
  }

  logEvent(data, eventText) async {
    data['log'].add(eventText);
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
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
                : Theme.of(context).highlightColor,
          ),
        ),
      );
    });

    return Container(
      width: 140,
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
                '> ' + latestLog + ' <',
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

  getGameboard(data) {
    return Stack(
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(
                      'Room code: ${widget.roomCode}',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    getDrawPile(data),
                    SizedBox(height: 15),
                    widget.userId == data['turn']
                        ? data['cardsToPlay'] > 0
                            ? getGiveUpButton(data)
                            : getEndTurnButton(data)
                        : Container(height: 30),
                  ],
                ),
                SizedBox(width: 30),
                Column(children: <Widget>[
                  getStatus(data),
                  SizedBox(height: 10),
                  showLog(data),
                ]),
              ],
            ),
            getCenterCards(data),
            isSpectator ? Container() : getHand(data),
            widget.userId == data['leader']
                ? EndGameButton(
                    gameName: 'Rivers',
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
          ],
        ),
        isSpectator
            ? Positioned(bottom: 35, right: 15, child: SpectatorModeLogo())
            : Container(),
      ],
    );
  }

  getScoreboard(data) {
    List<Widget> scores = [
      Text(
        'Draw Pile: ${data['drawPile'].length}',
        style: TextStyle(
          fontSize: 20,
        ),
      )
    ];
    data['playerIds'].asMap().forEach((i, v) {
      var playerName = data['playerNames'][v];
      var playerCardsRemaining = data['player${i}Hand'].length;
      scores.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$playerName: $playerCardsRemaining',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ],
        ),
      );
    });
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          data['finalScore'] != 0
              ? Column(
                  children: <Widget>[
                    Text(
                      'The game is over!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'The final score was:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      '${data['finalScore']}',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    )
                  ],
                )
              : Text(
                  'Amazing job!\n\nYou\'ve beaten Rivers!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
          SizedBox(height: 30),
          data['finalScore'] != 0
              ? Column(
                  children: <Widget>[
                    Text(
                      'Remaining cards:',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    Column(children: scores),
                  ],
                )
              : Container(),
          SizedBox(height: 50),
          widget.userId == data['leader']
              ? EndGameButton(
                  gameName: 'Rivers',
                  sessionId: widget.sessionId,
                  fontSize: 14,
                  height: 30,
                  width: 100,
                )
              : Text(
                  '(Glorious leader can take you back to the lobby)',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
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
                    'Rivers',
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
                  'Rivers',
                ),
              ),
              body: Container(),
            );
          }
          checkIfExit(data);
          // check if current player's turn
          checkIfVibrate(data);
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(
                'Rivers',
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
                          return RiversScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: data['state'] == 'started'
                ? getGameboard(data)
                : getScoreboard(data),
          );
        });
  }
}

class RiversScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'Rivers: Rules',
      information: [
        '    Welcome to Rivers! In this game, we\'re going to work together! Players take turns playing cards, and the '
            'objective of the game is to play every single card!\n\n    With standard rules, the deck contains cards from 2 to '
            '99, one of each. While there are cards remaining in the draw pile, player must play at least two cards. Once the '
            'draw pile runs out of cards, players must play at least one card. ',
        '    There are four piles to play on: two ascending piles and two descending piles. The rules for playing a card are '
            'simple: you can only play cards higher than the current card for ascending piles, and cards lower than the current card '
            'for descending piles.\n\n    The only exception is a card exactly 10 lower on ascending piles, and 10 higher on descending '
            'piles. For examples, for an ascending pile that is currently at 42, a player could play 43, 44, 45, etc., and the best card '
            'to play would be a 32. But not 41, 40, 39, etc. ',
        '    The final major rule is that players cannot specify what numbered cards they have in any way. Players can say things like '
            '"Don\'t play on this pile", or "I have something really good for the left ascending pile", or "Definitely, definitely don\'t '
            'play on 35". But nothing that could definitively describe a specific number.\n\n'
            '    The game ends when all cards are played (amazing job!), or if a player cannot play the required number of cards. The score '
            'is counted by the remaining unplayed cards in players\' hands and in the draw pile. '
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}

class RiversCard extends StatelessWidget {
  final String value;
  final Function callback;
  final bool clickable;
  final bool extraClickable;
  final bool empty;
  final bool flipped;
  final bool clicked;
  final bool isCenter;
  final int numCards;

  RiversCard({
    this.value,
    this.callback,
    this.clickable,
    this.numCards = 7,
    this.extraClickable = false,
    this.empty = false,
    this.flipped = false,
    this.clicked = false,
    this.isCenter = false,
  });

  getIcon(double iconSize) {
    var icon = MdiIcons.ladybug;
    var color = Colors.red;
    int intValue = int.parse(value);
    if (intValue >= 10 && intValue < 20) {
      icon = MdiIcons.ninja;
      color = Colors.green;
    }
    if (intValue >= 20 && intValue < 30) {
      icon = MdiIcons.jellyfishOutline;
      color = Colors.purple;
    }
    if (intValue >= 30 && intValue < 40) {
      icon = MdiIcons.ufoOutline;
      color = Colors.lime;
    }
    if (intValue >= 40 && intValue < 50) {
      icon = MdiIcons.rocketOutline;
      color = Colors.grey;
    }
    if (intValue >= 50 && intValue < 60) {
      icon = MdiIcons.atom;
      color = Colors.blue;
    }
    if (intValue >= 60 && intValue < 70) {
      icon = MdiIcons.beehiveOutline;
      color = Colors.amber;
    }
    if (intValue >= 70 && intValue < 80) {
      icon = MdiIcons.feather;
      color = Colors.indigo;
    }
    if (intValue >= 80 && intValue < 90) {
      icon = MdiIcons.footPrint;
      color = Colors.brown;
    }
    if (intValue >= 90 && intValue <= 100) {
      icon = MdiIcons.silverwareVariant;
      color = Colors.teal;
    }
    return Container(
      // decoration: BoxDecoration(border: Border.all()),
      child: Icon(
        icon,
        size: iconSize,
        color: color.withAlpha(140),
      ),
    );
  }

  getIconBackground(double iconSize) {
    return Transform.rotate(
      angle: 0, //0.2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getIcon(iconSize),
              getIcon(iconSize),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getIcon(iconSize),
              getIcon(iconSize),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getIcon(iconSize),
              getIcon(iconSize),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double width = (screenWidth - 20 - 5 * numCards) / numCards;
    double height = width * 1.5;
    double fontSize = [40.0, width * 0.5].reduce(min);
    double iconSize = [(width - 10) / 2, (height - 10) / 3].reduce(min);
    Color textColor = Colors.black;
    if (isCenter) {
      height = 100;
      width = 80;
      fontSize = 40;
      iconSize = 28;
    }
    if (empty) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'X',
            style: TextStyle(
              color: Colors.red,
              fontSize: 40,
            ),
          ),
        ),
      );
    }
    if (flipped) {
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
          child: Center(
            child: Container(
              height: height - 10,
              width: width - 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.pinkAccent,
                    Colors.blue,
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  MdiIcons.waves,
                  size: 40,
                ),
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
          border: Border.all(
            color: clicked
                ? Colors.blue
                : clickable
                    ? Colors.lightGreen
                    : extraClickable ? Colors.indigoAccent : Colors.black,
            width: clickable || clicked || extraClickable ? 5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: <Widget>[
              Center(
                child: getIconBackground(iconSize),
              ),
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
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
