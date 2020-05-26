import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:together/components/buttons.dart';

import 'package:together/components/misc.dart';
import 'package:together/components/layouts.dart';
import 'template/help_screen.dart';

class TheHuntScreen extends StatefulWidget {
  TheHuntScreen({this.sessionId, this.userId, this.roomCode, this.isLeader});

  final String sessionId;
  final String userId;
  final String roomCode;
  final bool isLeader;

  @override
  _TheHuntScreenState createState() => _TheHuntScreenState();
}

class _TheHuntScreenState extends State<TheHuntScreen> {
  String location;
  String role;
  List<dynamic> possibleLocations;
  List<dynamic> subList1;
  List<dynamic> subList2;
  List<List<bool>> strikethroughs;
  bool roleIsVisible = false;

  @override
  void initState() {
    super.initState();
    setUpGame();
  }

  setUpGame() async {
    Map<String, dynamic> session = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    setState(() {
      possibleLocations = session['rules']['locations'];
      subList2 = possibleLocations.sublist(0, possibleLocations.length ~/ 2);
      subList1 = possibleLocations.sublist(possibleLocations.length ~/ 2);
      strikethroughs = [
        List.filled(subList1.length, false),
        List.filled(subList2.length, false),
      ];
    });
    // check if game is set up and current user is leader
    if (!widget.isLeader) {
      print('non-leader does not set up game');
    } else if (session.containsKey('setupComplete')) {
      print('game is already set up');
    } else {
      // if not, identify players, set location, assign spies, then assign random roles for everyone else
      // eventually a backend service takes care of this?
      final _random = new Random();
      var playerIds = session['playerIds'];
      playerIds.shuffle();

      // set location
      location = possibleLocations[_random.nextInt(possibleLocations.length)];
      print('location is $location');

      // set spies
      int numSpies = session['rules']['numSpies'];
      var i = 0;
      while (i < numSpies) {
        await Firestore.instance
            .collection('users')
            .document(playerIds[i])
            .updateData({'huntRole': 'spy', 'huntLocation': location});
        i += 1;
      }

      // set other roles
      List<dynamic> possibleRoles = (await Firestore.instance
              .collection('locations')
              .document(location)
              .get())
          .data['roles'];
      while (i < playerIds.length) {
        await Firestore.instance
            .collection('users')
            .document(playerIds[i])
            .updateData({
          'huntRole': possibleRoles[_random.nextInt(possibleRoles.length)],
          'huntLocation': location,
        });
        i += 1;
      }
    }

    // for everyone
    var userId = (await FirebaseAuth.instance.currentUser()).uid;
    Map<String, dynamic> document =
        (await Firestore.instance.collection('users').document(userId).get())
            .data;
    setState(() {
      role = document['huntRole'];
      location = document['huntLocation'];
    });

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'setupComplete': true});
  }

  updateTurn() async {
    Map<String, dynamic> sessionData = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    var currActivePlayer = sessionData['turnPlayerId'];
    var allPlayers = sessionData['playerIds'];
    var activePlayerIndex = allPlayers.indexOf(currActivePlayer);
    var nextActivePlayer;
    if (activePlayerIndex == allPlayers.length - 1) {
      nextActivePlayer = allPlayers[0];
    } else {
      nextActivePlayer = allPlayers[activePlayerIndex + 1];
    }
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({'turnPlayerId': nextActivePlayer});
  }

  fakeCallback() {}

  StreamBuilder<QuerySnapshot> getTurn(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('sessions')
            .where('roomCode', isEqualTo: widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text(
              'No Data...',
            );
          } else {
            DocumentSnapshot items = snapshot.data.documents[0];
            var players = items['playerIds'];
            var activePlayer = items['turnPlayerId'];
            List<Widget> names = [];
            players.forEach((val) {
              names.add(
                FutureBuilder(
                    future: Firestore.instance
                        .collection('users')
                        .document(val)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      return Text(
                        snapshot.data['name'],
                        style: TextStyle(
                            color: val == activePlayer
                                ? Theme.of(context).primaryColor
                                : Colors.black),
                      );
                    }),
              );
            });
            return FutureBuilder(
              future: Firestore.instance
                  .collection('users')
                  .document(activePlayer)
                  .get(),
              builder: (context, snapshot) {
                return Container(
                  width: 250,
                  decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      widget.userId == activePlayer
                          ? Text(
                              'It is your turn!',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              'It is ${snapshot.data['name']}\'s turn!',
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                      PageBreak(width: 80),
                      Column(children: names),
                      SizedBox(height: 10),
                      widget.userId == activePlayer
                          ? RaisedGradientButton(
                              child: Text(
                                'End my turn',
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed: updateTurn,
                              height: 40,
                              width: 180,
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).accentColor,
                                ],
                              ),
                            )
                          : Container(),
                    ],
                  ),
                );
              },
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'The Hunt!',
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
                      return TheHuntScreenHelp();
                    },
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getTurn(context),
              SizedBox(height: 20),
              FlatButton(
                splashColor: Color.fromARGB(0, 1, 1, 1),
                highlightColor: Color.fromARGB(0, 1, 1, 1),
                onPressed: () {
                  setState(() {
                    roleIsVisible = !roleIsVisible;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: EdgeInsets.all(10),
                  width: 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        roleIsVisible
                            ? '(Tap to hide role)'
                            : 'Tap to show role',
                        style: TextStyle(
                            fontSize: roleIsVisible ? 16 : 20,
                            color: roleIsVisible
                                ? Colors.grey[400]
                                : Colors.white),
                      ),
                      roleIsVisible
                          ? SizedBox(
                              height: 10,
                            )
                          : Container(),
                      roleIsVisible && location != null && role != null
                          ? role == 'spy'
                              ? Column(
                                  children: <Widget>[
                                    Text(
                                      'You are the spy!',
                                      style: TextStyle(
                                          fontSize: 22, color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '(Try and figure out the location!)',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[300]),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                )
                              : Column(
                                  children: <Widget>[
                                    Text(
                                      'Location:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    Text(
                                      '$location',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Your role:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '$role',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )
                          : Container(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              possibleLocations != null
                  ? LocationBoard(
                      subList1: subList1,
                      subList2: subList2,
                      strikethroughs: strikethroughs,
                      callback: fakeCallback,
                    )
                  : Container(),
              SizedBox(
                height: 20,
              ),
              Text(
                'Room Code:',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              PageBreak(width: 80),
              Text(
                widget.roomCode,
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ));
  }
}

class TheHuntScreenHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HelpScreen(
      title: 'The Hunt: Rules',
      information: [
        '    The objectives of the game are simple:\n\n(1) If you ARE NOT a spy, you are a citizen trying to find the spy(ies). \n\n(2) If you ARE a spy, '
            'you are trying to figure out where the location is.\n\n(3) Spies lose and win, together. Same for citizens.',
        '    Players take turns asking questions to a player of their choice. The question can be anything, '
            'and the answer can be anything.\n\n    Just keep in mind that vagueness can be suspicious!',
            '    At any point, a player can accuse another player of being the spy.\n\n    '
            'A verdict requires a unanimous vote, less the remaining number of spies.',
            '    The game ends in two general ways:\n\n(1) A spy can reveal they are the spy at any time, and attempt to guess the location. '
            'If they guess correctly, the spies win. If they guess incorrectly, the spies lose.'
            '\n\n(2) If a player is unanimously accused and there is only one spy left, the citizens win. If there is more than one spy, '
            'the accused (if a spy) gets a chance to guess the location before getting sentenced to silence (following #1 rules for winning).'
      ],
      buttonColor: Theme.of(context).primaryColor,
    );
  }
}
