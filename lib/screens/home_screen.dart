import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../services/services.dart';
import '../services/authentication.dart';

import 'package:together/components/buttons.dart';
import 'package:together/components/marquee.dart';

import 'settings_screen.dart';
import 'achievements_screen.dart';
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

  getGamesMarquee(BuildContext context) {
    Color colorHunt = Colors.black;
    Color colorAbstract = Colors.green;
    Color colorBananaphone = Colors.blue;
    Color colorThreeCrowns = Colors.amber;
    Color colorRivers = Colors.lightBlue;
    double intervalLength = 25.0;
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(height: 5),
          Row(
            children: <Widget>[
              SizedBox(width: intervalLength),
              QuickStartButton(
                gameName: 'The Hunt',
                subtitle: 'Spies vs. Citizens!',
                icon: Icon(
                  MdiIcons.incognito,
                  color: colorHunt,
                  size: 30,
                ),
              ),
              SizedBox(width: intervalLength),
              QuickStartButton(
                gameName: 'Rivers',
                subtitle: 'Up and down!',
                icon: Icon(
                  MdiIcons.waves,
                  color: colorRivers,
                  size: 30,
                ),
              ),
              SizedBox(width: intervalLength),
              QuickStartButton(
                gameName: 'Abstract',
                subtitle: 'Connect concepts!',
                icon: Icon(
                  MdiIcons.resistorNodes,
                  color: colorAbstract,
                  size: 30,
                ),
              ),
              SizedBox(width: intervalLength),
              QuickStartButton(
                gameName: 'Bananaphone',
                subtitle: 'Draw and pass it on!',
                icon: Icon(
                  MdiIcons.phoneSettings,
                  color: colorBananaphone,
                  size: 30,
                ),
              ),
              SizedBox(width: intervalLength),
              QuickStartButton(
                gameName: 'Three Crowns',
                subtitle: 'Coming soon!',
                icon: Icon(
                  MdiIcons.crown,
                  color: colorThreeCrowns,
                  size: 30,
                ),
              ),
              SizedBox(width: intervalLength),
            ],
          ),
          SizedBox(height: 5),
        ],
      ),
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
                  icon: Icon(MdiIcons.trophy),
                  onPressed: () {
                    slideTransition(
                      context,
                      AchievementsScreen(
                        userId: widget.userId,
                      ),
                    );
                  },
                ),
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
                  Text(
                    'Quick Start',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '* no password',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 10),
                  Marquee(
                    child: getGamesMarquee(context),
                    animationDuration: Duration(seconds: 13),
                    backDuration: Duration(seconds: 13),
                    pauseDuration: Duration(seconds: 3),
                    directionMarguee: DirectionMarguee.TwoDirection,
                  ),
                  SizedBox(height: 40),
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
        String sessionId = event.documents.single.documentID;

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

        // remove player from previous game
        await checkUserInGame(
            userId: userId, sessionId: event.documents.single.documentID);

        // determine if user needs to be added as a player or spectator
        if (data['state'] == 'lobby') {
          if (!data['playerIds'].contains(userId) &&
              !data['spectatorIds'].contains(userId)) {
            data['playerIds'].add(userId);
          }
        }
        // if game has started, either user is a player or will get added as a spectator
        if (data['state'] != 'lobby' && !data['playerIds'].contains(userId)) {
          // add if they are not a spectator yet
          if (!data['spectatorIds'].contains(userId)) {
            data['spectatorIds'].add(userId);
          }
        }
        await Firestore.instance
            .collection('sessions')
            .document(sessionId)
            .setData(data);

        // update player's currentGame
        await Firestore.instance
            .collection('users')
            .document(userId)
            .updateData({'currentGame': sessionId});

        // move to room
        Navigator.of(context).pop();
        slideTransition(
          context,
          LobbyScreen(
            roomCode: _roomCodeController.text.toUpperCase(),
          ),
        );
      } else {
        // room doesn't exist
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
        icon = Icon(MdiIcons.phoneSettings, color: color);
        break;
      case 'Rivers':
        color = Colors.lightBlue;
        icon = Icon(MdiIcons.waves, color: color);
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
                      'Rivers',
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
        FlatButton(
            onPressed: () {
              widget.isJoin
                  ? joinGame(_roomCodeController.text, _passwordController.text)
                  : createGame(
                      context, _dropDownGame, _passwordController.text, true);
            },
            child: Text('Confirm'))
      ],
    );
  }
}

class QuickStartButton extends StatelessWidget {
  final String gameName;
  final String subtitle;
  final Icon icon;

  QuickStartButton({
    this.gameName,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        createGame(context, gameName, '', false);
      },
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: 1.0,
              offset: Offset(
                1.0,
                1.0,
              ),
            )
          ],
          gradient: LinearGradient(
            colors: <Color>[
              Colors.blue[800],
              Colors.blue[400],
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: icon,
            ),
            SizedBox(height: 5),
            AutoSizeText(
              gameName,
              maxLines: 1,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
