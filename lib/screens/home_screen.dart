import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../services/services.dart';
import '../services/authentication.dart';

import 'package:together/components/buttons.dart';
import 'package:together/components/marquee.dart';

import 'settings_screen.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  signOutCallback() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  getGamesMarquee() {
    // return Text('yofskjfkdsjglidshzgkvjdxbngkjsdhfkshdkfgndskfghdsogfjndslkgjnsdklgdskjgbdksjnflskngkjsdbngkjdsbgkjdsbgjkdbsgkjbdskjgbds');
    Color colorHunt = Theme.of(context).highlightColor;
    Color colorAbstract = Colors.green;
    Color colorBananaphone = Colors.blue;
    Color colorThreeCrowns = Colors.amber;
    double intervalLength = 50.0;
    return Row(
      children: <Widget>[
        SizedBox(width: intervalLength),
        Column(
          children: <Widget>[
            Icon(
              MdiIcons.incognito,
              color: colorHunt,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              'The Hunt',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Spies vs. Citizens!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(width: intervalLength),
        Column(
          children: <Widget>[
            Icon(
              MdiIcons.resistorNodes,
              color: colorAbstract,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              'Abstract',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Connect concepts!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(width: intervalLength),
        Column(
          children: <Widget>[
            Icon(
              MdiIcons.phoneSettingsOutline,
              color: colorBananaphone,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              'Bananaphone',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Draw and pass it on!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(width: intervalLength),
        Column(
          children: <Widget>[
            Icon(
              MdiIcons.crown,
              color: colorThreeCrowns,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              'Three Crowns',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Coming soon!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(width: intervalLength),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('users')
            .document(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Main Menu',
                  ),
                ),
                body: Container());
          }
          // all data for all components
          var userData = snapshot.data.data;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Main Menu',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    slideTransition(
                      context,
                      SettingsScreen(
                        auth: widget.auth,
                        logoutCallback: signOutCallback,
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
                  // counter balance for REJOIN
                  Container(),
                  // SHOW ALL GAMES
                  Marquee(
                    child: getGamesMarquee(),
                    animationDuration: Duration(seconds: 10),
                    backDuration: Duration(seconds: 10),
                    pauseDuration: Duration(seconds: 2),
                    directionMarguee: DirectionMarguee.TwoDirection,
                  ),
                  SizedBox(height: 80),
                  // CREATE
                  RaisedGradientButton(
                    child: Text(
                      'Create a game',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    height: 60,
                    width: 200,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Theme.of(context).primaryColor,
                        Theme.of(context).accentColor,
                      ],
                    ),
                    onPressed: () {
                      showDialog<Null>(
                        context: context,
                        builder: (BuildContext context) {
                          return LobbyDialog(isJoin: false);
                        },
                      );
                    },
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  RaisedGradientButton(
                    child: Text(
                      'Join a game',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    height: 60,
                    width: 200,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Theme.of(context).primaryColor,
                        Theme.of(context).accentColor,
                      ],
                    ),
                    onPressed: () {
                      showDialog<Null>(
                        context: context,
                        builder: (BuildContext context) {
                          return LobbyDialog(isJoin: true);
                        },
                      );
                    },
                  ),
                  // if player has existing game, allow rejoin
                  StreamBuilder(
                      stream: Firestore.instance
                          .collection('sessions')
                          .document(userData['currentGame'])
                          .snapshots(),
                      builder: (context, sessionSnapshot) {
                        if (sessionSnapshot.hasData &&
                            sessionSnapshot.data.data == null) {
                          return Container();
                        }
                        return Column(
                          children: <Widget>[
                            SizedBox(
                              height: 40,
                            ),
                            RaisedGradientButton(
                              child: Text(
                                'Rejoin game',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              height: 60,
                              width: 200,
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Color.fromARGB(255, 255, 185, 0),
                                  Color.fromARGB(255, 255, 213, 0),
                                ],
                              ),
                              onPressed: () {
                                slideTransition(
                                  context,
                                  LobbyScreen(
                                    roomCode:
                                        sessionSnapshot.data.data['roomCode'],
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }),
                  // offset for game list
                  SizedBox(height: 50),
                ],
              ),
            ),
          );
        });
  }
}

class LobbyDialog extends StatefulWidget {
  LobbyDialog({this.isJoin});

  final bool isJoin;

  @override
  _LobbyDialogState createState() => _LobbyDialogState();
}

class _LobbyDialogState extends State<LobbyDialog> {
  TextEditingController _passwordController = new TextEditingController();
  TextEditingController _roomCodeController = new TextEditingController();
  // TODO: make default game choice in settings?
  String _dropDownGame = 'The Hunt';
  String _roomCode = '';
  bool isFormError = false;
  String formError = '';

  getDefaultRules(String gameName) {
    switch (gameName) {
      case 'The Hunt':
        return {
          'locations': ['Casino', 'Pirate Ship', 'Coal Mine', 'University'],
          'numSpies': 1,
        };
        break;
      case 'Abstract':
        return {
          'numTeams': 2,
          'turnTimer': 30,
        };
        break;
      case 'Bananaphone':
        return {
          'numRounds': 2,
          'numDrawDescribe': 2,
        };
        break;
      case 'Three Crowns':
        return {
          'maxWordLength': 6,
        };
    }
  }

  checkUserInGame({String userId, String sessionId = ''}) async {
    // check if player has currentGame (that is not this game). if so, remove player from currentGame
    var userData =
        (await Firestore.instance.collection('users').document(userId).get())
            .data;
    if (userData.containsKey('currentGame')) {
      print('user is still in game ${userData['currentGame']}, will remove');
      var session = await Firestore.instance
          .collection('sessions')
          .document(userData['currentGame'])
          .get();
      var sessionData = session.data;

      // if old game still exists and is not this game
      if (sessionData != null &&
          (sessionId == '' || sessionId != session.documentID)) {
        // remove user from playerIds in old game
        await Firestore.instance
            .collection('sessions')
            .document(userData['currentGame'])
            .updateData({
          'playerIds': FieldValue.arrayRemove([userId])
        });
        // check if room is empty, if so, delete session
        var playerIds = (await Firestore.instance
                .collection('sessions')
                .document(userData['currentGame'])
                .get())
            .data['playerIds'];
        if (playerIds.length == 0) {
          await Firestore.instance
              .collection('sessions')
              .document(userData['currentGame'])
              .delete();
        }
      }
    } else {
      print('user is not in another game, no problem');
    }
  }

  createGame(String game, String password) async {
    final _rnd = Random();
    final letters = 'ABCDEFGHJKMNPQRSTUVWXYZ';
    String randLetter() => letters[_rnd.nextInt(letters.length)];
    String randRoomCode() => randLetter() + randLetter() + randLetter();
    _roomCode = randRoomCode();

    // check that room code doesn't exist
    bool roomCodeExists = true;
    while (roomCodeExists) {
      await Firestore.instance
          .collection('sessions')
          .where('roomCode', isEqualTo: _roomCode)
          .getDocuments()
          .then((event) async {
        if (event.documents.isEmpty) {
          roomCodeExists = false;
        } else {
          _roomCode = randRoomCode();
        }
      }).catchError((e) => print('error fetching data: $e'));
    }

    // remove user from old game
    final userId = (await FirebaseAuth.instance.currentUser()).uid;
    checkUserInGame(userId: userId);

    // define initial rules per game
    Map<String, dynamic> defaultRules = getDefaultRules(game);

    var sessionContents = {
      'game': game,
      'rules': defaultRules,
      'password': password,
      'roomCode': _roomCode,
      'playerIds': [userId],
      'state': 'lobby',
      'leader': userId,
      'dateCreated': DateTime.now(),
      'setupComplete': false,
    };
    switch (game) {
      case 'The Hunt':
        sessionContents['turn'] = userId;
        break;
      case 'Abstract':
        sessionContents['turn'] = 'green';
        break;
      case 'Bananaphone':
        sessionContents['phase'] = 'draw1';
        sessionContents['round'] = 0;
        break;
      case 'Three Crowns':
        sessionContents['turn'] = userId;
    }
    var result =
        await Firestore.instance.collection('sessions').add(sessionContents);

    // update user's current game
    await Firestore.instance
        .collection('users')
        .document(userId)
        .updateData({'currentGame': result.documentID});

    // vibrate
    HapticFeedback.vibrate();

    // navigate to lobby
    Navigator.of(context).pop();
    slideTransition(
      context,
      LobbyScreen(
        roomCode: _roomCode.toUpperCase(),
      ),
    );
  }

  joinGame(String roomCode, String password) async {
    roomCode = roomCode.toUpperCase();
    final userId = (await FirebaseAuth.instance.currentUser()).uid;

    await Firestore.instance
        .collection('sessions')
        .where('roomCode', isEqualTo: roomCode)
        .getDocuments()
        .then((event) async {
      if (event.documents.isNotEmpty) {
        var data = event.documents.single.data;

        // check password
        var correctPassword = data['password'];
        if (correctPassword != '') {
          if (correctPassword != _passwordController.text) {
            setState(() {
              isFormError = true;
              formError = 'Incorrect password';
            });
            // break if form error
            return;
          }
        }

        // if game has started and player is not in session, reject
        if (data['state'] == 'started' && !data['playerIds'].contains(userId)) {
          setState(() {
            isFormError = true;
            formError = 'Game has already started';
          });
          return;
        }

        // remove player from previous game
        await checkUserInGame(
            userId: userId, sessionId: event.documents.single.documentID);

        // otherwise, append playerId to session
        String sessionId = event.documents.single.documentID;
        await Firestore.instance
            .collection('sessions')
            .document(sessionId)
            .updateData({
          'playerIds': FieldValue.arrayUnion([userId])
        });

        // update player's currentGame
        await Firestore.instance
            .collection('users')
            .document(userId)
            .updateData({'currentGame': sessionId});

        // only move to room if password is correct
        if (!isFormError) {
          Navigator.of(context).pop();
          slideTransition(
            context,
            LobbyScreen(
              roomCode: _roomCodeController.text.toUpperCase(),
            ),
          );
        }
      } else {
        // room doesn't exist
        print('room doesn\'t exist');
        setState(() {
          isFormError = true;
          formError = 'Room does not exist';
        });
      }
    }).catchError((e) => print('error fetching data: $e'));
  }

  leaveGame() async {
    // remove player from session document, if there are no other players, delete document
    // update player document's current game to none
  }

  getDropdownWithIcon(value) {
    var icon = Icon(MdiIcons.incognito); // default hunt
    Color color = Theme.of(context).highlightColor;
    switch (value) {
      case 'Abstract':
        color = Colors.green;
        icon = Icon(MdiIcons.resistorNodes, color: color);
        break;
      case 'Bananaphone':
        color = Colors.blue;
        icon = Icon(MdiIcons.phoneSettingsOutline, color: color);
        break;
      case 'Three Crowns':
        color = Colors.amber;
        icon = Icon(MdiIcons.crown, color: color);
        break;
    }
    return Row(
      children: <Widget>[
        icon,
        SizedBox(width: 30),
        Text(
          value,
          style: TextStyle(fontFamily: 'Balsamiq', color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isJoin ? 'Join a game' : 'Create a game'),
      content: Container(
        height: 140.0,
        width: 100.0,
        child: ListView(
          children: <Widget>[
            widget.isJoin
                ? Container()
                : DropdownButton<String>(
                    value: _dropDownGame,
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (String newValue) {
                      setState(() {
                        _dropDownGame = newValue;
                      });
                    },
                    items: <String>[
                      'The Hunt',
                      'Abstract',
                      'Bananaphone',
                      'Three Crowns',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: getDropdownWithIcon(value),
                      );
                    }).toList(),
                  ),
            widget.isJoin
                ? TextField(
                    onChanged: (s) {
                      setState(() {
                        isFormError = false;
                        formError = '';
                      });
                    },
                    controller: _roomCodeController,
                    decoration: InputDecoration(labelText: 'Room Code: '),
                  )
                : Container(),
            TextField(
              onChanged: (s) {
                setState(() {
                  isFormError = false;
                  formError = '';
                });
              },
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password (optional):',
              ),
            ),
            SizedBox(height: 8),
            isFormError
                ? Text(formError,
                    style: TextStyle(color: Colors.red, fontSize: 14))
                : Container(),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel")),
        // This button results in adding the contact to the database
        FlatButton(
            onPressed: () {
              widget.isJoin
                  ? joinGame(_roomCodeController.text, _passwordController.text)
                  : createGame(_dropDownGame, _passwordController.text);
            },
            child: Text('Confirm'))
      ],
    );
  }
}
