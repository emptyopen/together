import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:together/components/buttons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:math';

import 'package:together/services/services.dart';
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

  fillHand(data) async {
    data = data.data;
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    bool changed = false;
    var cnt = 0;
    while (data['player${playerIndex}Hand'].length < 5 && cnt < 8) {
      String randomCard = generateRandomCard();
      data['player${playerIndex}Hand'].add(randomCard);
      changed = true;
      cnt += 1;
    }
    if (changed) {
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .setData(data);
    }
  }

  getHand(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    List<Widget> cards = [];
    // angles: 5 cards -> -80, -40, 0, 40, 80
    // 4 cards -> -60, -20, 20, 60
    var angles = [-pi / 5, -pi / 10, 0.0, pi / 10, pi / 5];
    switch (cards.length) {
      case 1:
        angles = [0.0];
        break;
      case 2:
        angles = [pi / 3, pi / 3];
        break;
      case 3:
        angles = [-pi / 3, 0.0, pi / 3];
        break;
      case 4:
        angles = [-pi / 3, -pi / 6, pi / 6, pi / 3];
        break;
    }
    print('angles $angles');
    data['player${playerIndex}Hand'].asMap().forEach((i, val) {
      var card = Transform.rotate(
          angle: angles[i],
          child: Card(
        value: val,
        size: 'medium',
      ),);
      cards.add(card);
    });
    return Container(
      width: 350,
      height: 200,
      decoration: BoxDecoration(border: Border.all()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: cards,
      ),
    );
  }

  getGameboard(data) {
    fillHand(data);
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(border: Border.all()),
        height: height,
        width: width,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Text('STATUS'),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  getHand(data),
                  SizedBox(height: 50),
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
          DocumentSnapshot data = snapshot.data;
          if (data.data == null) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Three Crowns',
                  ),
                ),
                body: Container());
          }
          checkIfExit(data);
          // check if hand needs to be refilled
          fillHand(data);
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

  Card({
    this.value,
    this.size,
    this.rotation,
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
    double fontSize = 30;
    if (size == 'medium') {
      // do nothing
    }
    return Container(
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
        ));
  }
}
