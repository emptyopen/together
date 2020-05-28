import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:together/components/buttons.dart';

import 'package:together/components/misc.dart';
import 'package:together/components/layouts.dart';
import 'package:together/services/services.dart';
import 'template/help_screen.dart';
import 'lobby_screen.dart';

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
  String gameName;
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

  checkIfExit() async {
    // run async func to check if game is back to lobby or deleted (main menu)
    var data = (await Firestore.instance.collection('sessions').document(widget.sessionId).get()).data;
    if (data == null) {
      print('game was deleted');
      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      // reset first player
      String firstPlayer = data['playerIds'][0];
      await Firestore.instance.collection('sessions').document(widget.sessionId).updateData({'turnPlayerId': firstPlayer});
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

  setUpGame() async {
    Map<String, dynamic> session = (await Firestore.instance
            .collection('sessions')
            .document(widget.sessionId)
            .get())
        .data;
    setState(() {
      gameName = session['gameName'];
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
          // check if exit here, only on update
          checkIfExit();
          if (!snapshot.hasData || snapshot.data.documents.length == 0) {
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
        body: SingleChildScrollView(
                  child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 50),
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
                SizedBox(height: 20),
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
                SizedBox(height: 30),
                RaisedGradientButton(
                  child: Text(
                    'End game',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    showDialog<Null>(
                      context: context,
                      builder: (BuildContext context) {
                        return EndGameDialog(
                          sessionId: widget.sessionId,
                        );
                      },
                    );
                  },
                  height: 40,
                  width: 140,
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color.fromARGB(255, 255, 185, 0),
                      Color.fromARGB(255, 255, 213, 0),
                    ],
                  ),
                ),
                SizedBox(height: 80),
              ],
            ),
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

class EndGameDialog extends StatefulWidget {
  EndGameDialog({this.sessionId});

  final String sessionId;

  @override
  _EndGameDialogState createState() => _EndGameDialogState();
}

class _EndGameDialogState extends State<EndGameDialog> {
  String spiesOrCitizensWon = 'Spies';

  endGame(bool isToLobby) async {
    // leader can end game if someone won
    // assign winner (add statistics)
    // choice of lobby for another game or back to main menu
    if (isToLobby) {
      print('will end game and go to lobby');
      // update session state to lobby - this automatically will trigger to lobby
      await Firestore.instance.collection('sessions').document(widget.sessionId).updateData({'state': 'lobby'});
      Navigator.of(context).pop();
    } else {
      await Firestore.instance.collection('sessions').document(widget.sessionId).delete();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Text('End the game!'),
      contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
      content: Container(
        height: 180,
        width: width * 0.95,
        child: ListView(
          children: <Widget>[
            SizedBox(height: 20),
            Text('Who won?'),
            Container(
              width: 80,
              child: DropdownButton<String>(
                isExpanded: true,
                value: spiesOrCitizensWon,
                iconSize: 24,
                elevation: 16,
                style: TextStyle(color: Theme.of(context).primaryColor),
                underline: Container(
                  height: 2,
                  color: Theme.of(context).primaryColor,
                ),
                onChanged: (String newValue) {
                  setState(() {
                    spiesOrCitizensWon = newValue;
                  });
                },
                items: <String>['Spies', 'Citizens']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child:
                        Text(value, style: TextStyle(fontFamily: 'Balsamiq', fontSize: 18,)),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 10),
            Text('End game and go back to:'),
            SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(
                  height: 50,
                  width: 110,
                  child: RaisedGradientButton(
                    child: Text(
                      'Lobby',
                      style: TextStyle(fontSize: 18),
                    ),
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color.fromARGB(255, 255, 185, 0),
                        Color.fromARGB(255, 255, 213, 0),
                      ],
                    ),
                    onPressed: () => endGame(true),
                  ),
                ),
                Container(
                  height: 50,
                  width: 150,
                  child: RaisedGradientButton(
                    child: Text(
                      'Main Menu',
                      style: TextStyle(fontSize: 18),
                    ),
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color.fromARGB(255, 255, 185, 0),
                        Color.fromARGB(255, 255, 213, 0),
                      ],
                    ),
                    onPressed: () => endGame(false),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      actions: <Widget>[
        Container(
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
