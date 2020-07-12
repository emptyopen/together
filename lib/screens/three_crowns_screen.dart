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

  determineDuelWinner(data) {
    // determine dueler and duelee
    // compare cards
    // if there is a winner, allow matching or "kneel"
    // if there is a tie, move to second joust
    // if there is a siege ("A" and "face card"), winner gets to pillage (steal tile if available or get two tiles)
  }

  playCard(data, i, val) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    if (playerIndex == data['duel']['duelerIndex']) {
      // player is dueler
      if (data['duel']['duelerCard'] != '') {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Already played! Remove your played card to play another.'),
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
          content: Text('Already played! Remove your played card to play another.'),
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
              border: Border.all(),
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
        : Card(
            value: oppositeCardValue,
            size: 'medium',
          );
    var playerCard = playerCardValue == ''
        ? Container(
            height: 80,
            width: 60,
            decoration: BoxDecoration(
              border: Border.all(),
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
      height: 200,
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
    bool playerIsInDuel = playerInDuel(data, widget.userId);
    if (playerIsInDuel) {
      var opponent = data['playerIds']
          [data['duel']['duelerIndex']]; //data['playerNames'][]
      if (playerIsDueler(data)) {
        opponent = data['playerIds'][data['duel']['duelerIndex'] + 1];
      }
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
    return Text('STATUS HERE');
  }

  getCenter(data) {
    // check if player is part of duel
    return Container(
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(10),
        ),
        height: 270,
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Container(child: getStatus(data)),
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
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: getCenter(data),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  getHand(data),
                  SizedBox(height: 60),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  EndGameButton(
                    sessionId: widget.sessionId,
                    height: 35,
                    width: 100,
                    gameName: 'Three Crowns',
                  ),
                  SizedBox(height: 5),
                ],
              ),
            ),
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

  Card({
    this.value,
    this.size,
    this.rotation,
    this.callback,
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
          color: Colors.black,
          size: size,
        );
        break;
      case 'H':
        return Icon(
          MdiIcons.cardsHeart,
          color: Colors.red,
          size: size,
        );
        break;
      case 'C':
        return Icon(
          MdiIcons.cardsClub,
          color: Colors.black,
          size: size,
        );
        break;
      case 'D':
        return Icon(
          MdiIcons.cardsDiamond,
          color: Colors.red,
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
    if (size == 'medium') {
      // do nothing
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
