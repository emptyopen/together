import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';

import '../services/services.dart';
import '../services/authentication.dart';
import 'package:together/constants/values.dart';
import 'package:together/components/buttons.dart';
import 'package:together/components/marquee.dart';
import 'package:together/components/info_box.dart';
import 'package:together/services/firestore.dart';

import 'settings_screen.dart';
import 'achievements/achievements_screen.dart';
import 'package:together/screens/game_tools/the_scoreboard_screen.dart';
import 'package:together/screens/game_tools/dice_and_coins_screen.dart';
import 'package:together/screens/game_tools/team_selector_screen.dart';
import 'lobby/lobby_screen.dart';
import 'package:together/screens/lobby/lobby_services.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List gamesUnderConstruction = [];

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
    double intervalLength = 25.0;
    List<Widget> quickStartWidgets = [SizedBox(width: intervalLength)];
    [
      inTheClubString,
      samesiesString,
      charadeATroisString,
      riversString,
      plotTwistString,
      threeCrownsString,
      bananaphoneString,
      abstractString,
      theHuntString,
    ].forEach((v) {
      quickStartWidgets.add(
        QuickStartButton(
          gameName: v,
          subtitle: gameSubtitles[v],
          icon: Icon(
            gameIcons[v],
            color: gameColors[v],
            size: 30,
          ),
          minPlayers: gameMinPlayers[v],
          underConstruction: gamesUnderConstruction.contains(v) ? true : false,
        ),
      );
      quickStartWidgets.add(
        SizedBox(width: intervalLength),
      );
    });
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(height: 5),
          Row(children: quickStartWidgets),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
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
          var userData = snapshot.data.data();
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(
                'Main Menu',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(MdiIcons.share),
                  onPressed: () {
                    showDialog<Null>(
                      context: context,
                      builder: (BuildContext context) {
                        return ShareLinkDialog(scaffoldKey: _scaffoldKey);
                      },
                    );
                  },
                ),
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
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Container(),
                      // SHOW ALL GAMES
                      Column(
                        children: [
                          Text(
                            'Quick Start',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '* no password',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 10),
                          Marquee(
                            child: getGamesMarquee(context),
                            animationDuration: Duration(seconds: 15),
                            backDuration: Duration(seconds: 13),
                            pauseDuration: Duration(seconds: 4),
                            directionMarguee: DirectionMarguee.TwoDirection,
                          ),
                        ],
                      ),
                      MainMenuButton(
                        title: 'Create game',
                        icon: MdiIcons.plusBox,
                        textColor: Colors.white,
                        gradient: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).accentColor,
                        ],
                        callback: () {
                          showDialog<Null>(
                            context: context,
                            builder: (BuildContext context) {
                              return LobbyDialog(isJoin: false);
                            },
                          );
                        },
                      ),
                      MainMenuButton(
                        title: 'Join game',
                        icon: MdiIcons.arrowRightBox,
                        textColor: Colors.white,
                        gradient: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).accentColor,
                        ],
                        callback: () {
                          showDialog<Null>(
                            context: context,
                            builder: (BuildContext context) {
                              return LobbyDialog(isJoin: true);
                            },
                          );
                        },
                      ),
                      MainMenuButton(
                        title: 'Other Tools',
                        icon: MdiIcons.dice3,
                        textColor: Colors.white,
                        gradient: [
                          Colors.cyan[700],
                          Colors.cyan[400],
                        ],
                        callback: () {
                          showDialog<Null>(
                            context: context,
                            builder: (BuildContext context) {
                              return ToolsDialog();
                            },
                          );
                        },
                      ),
                      StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('sessions')
                              .doc(userData['currentGame'])
                              .snapshots(),
                          builder: (context, sessionSnapshot) {
                            if (sessionSnapshot.hasData &&
                                sessionSnapshot.data.data == null) {
                              return Container();
                            }
                            return MainMenuButton(
                              title: 'Rejoin game',
                              icon: MdiIcons.chevronRightBox,
                              textColor: Colors.black,
                              gradient: [
                                Color.fromARGB(255, 255, 185, 0),
                                Color.fromARGB(255, 255, 213, 0),
                              ],
                              callback: () {
                                slideTransition(
                                  context,
                                  LobbyScreen(
                                    roomCode:
                                        sessionSnapshot.data.data()['roomCode'],
                                  ),
                                );
                              },
                            );
                          }),
                      Container(),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 2,
                  child: InfoBox(
                    text: 'Change your name here!',
                    infoKey: 'accountSection',
                    userId: widget.userId,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 50,
                  child: InfoBox(
                    text: 'See your achievements here!',
                    infoKey: 'achievementsSection',
                    userId: widget.userId,
                    dependentInfoKeys: ['accountSection'],
                  ),
                ),
              ],
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
  String formError = '';

  joinGame(String roomCode, String password) async {
    roomCode = roomCode.toUpperCase();
    final userId = FirebaseAuth.instance.currentUser.uid;

    await FirebaseFirestore.instance
        .collection('sessions')
        .where('roomCode', isEqualTo: roomCode)
        .get()
        .then((event) async {
      if (event.docs.isNotEmpty) {
        var data = event.docs.single.data();
        String sessionId = event.docs.single.id;
        var T = Transactor(sessionId: sessionId);

        // check password
        var correctPassword = data['password'];
        if (correctPassword != '') {
          if (correctPassword != _passwordController.text) {
            setState(() {
              formError = 'Incorrect password';
            });
            // break if form error
            return;
          }
        }

        // remove player from previous game
        await checkUserInGame(userId: userId, sessionId: event.docs.single.id);

        // determine if user needs to be added as a player or spectator
        if (data['state'] == 'lobby') {
          if (!data['playerIds'].contains(userId) &&
              !data['spectatorIds'].contains(userId)) {
            addPlayer(data, userId, T);
          }
        }
        // if game has started, either user is a player or will get added as a spectator
        if (data['state'] != 'lobby' && !data['playerIds'].contains(userId)) {
          // add if they are not a spectator yet
          if (!data['spectatorIds'].contains(userId)) {
            data['spectatorIds'].add(userId);
          }
        }
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .set(data);

        // update player's currentGame
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'currentGame': sessionId});

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
          formError = 'Room does not exist';
        });
      }
    }).catchError((e) {
      print('error fetching data: $e');
      setState(() {
        formError = 'Error: $e';
      });
    });
  }

  leaveGame() async {
    // remove player from session document, if there are no other players, delete document
    // update player document's current game to none
  }

  getDropdownWithIcon(value) {
    var icon = Icon(MdiIcons.incognito); // default hunt
    Color color = Theme.of(context).highlightColor;
    color = gameColors[value];
    icon = Icon(gameIcons[value], color: color);
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
                      'Rivers',
                      'Plot Twist',
                      'Charáde à Trois',
                      'Samesies',
                      'In The Club',
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
                        formError = '';
                      });
                    },
                    enableSuggestions: false,
                    autofocus: true,
                    autocorrect: false,
                    onSubmitted: (s) {
                      joinGame(
                          _roomCodeController.text, _passwordController.text);
                    },
                    controller: _roomCodeController,
                    decoration: InputDecoration(labelText: 'Room Code: '),
                  )
                : Container(),
            TextField(
              onChanged: (s) {
                setState(() {
                  formError = '';
                });
              },
              onSubmitted: (s) {
                joinGame(_roomCodeController.text, _passwordController.text);
              },
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password (optional):',
              ),
            ),
            SizedBox(height: 8),
            formError != ''
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
                  : createGame(context, _dropDownGame, _passwordController.text,
                      true, () => null);
            },
            child: Text('Confirm'))
      ],
    );
  }
}

class ShareLinkDialog extends StatelessWidget {
  final scaffoldKey;

  ShareLinkDialog({this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Copy app link'),
      content: Container(
        width: 100.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  MdiIcons.googlePlay,
                  size: 30,
                ),
                SizedBox(height: 10),
                Icon(
                  MdiIcons.appleIos,
                  size: 30,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      MdiIcons.googlePlay,
                      size: 30,
                    ),
                    Icon(
                      MdiIcons.appleIos,
                      size: 30,
                    ),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'play store',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'ios store',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'both',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(width: 40),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.vibrate();
                    FlutterClipboard.copy(
                            'https://play.google.com/store/apps/details?id=com.takaomatt.together')
                        .then((value) {
                      scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text('google play store link copied!'),
                        duration: Duration(seconds: 3),
                      ));
                    });
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    MdiIcons.contentCopy,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.vibrate();
                    FlutterClipboard.copy(
                            'https://apps.apple.com/app/id1514995376')
                        .then((value) {
                      scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text('ios store link copied!'),
                        duration: Duration(seconds: 3),
                      ));
                    });
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    MdiIcons.contentCopy,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.vibrate();
                    FlutterClipboard.copy(
                            'https://play.google.com/store/apps/details?id=com.takaomatt.together\nhttps://apps.apple.com/app/id1514995376')
                        .then((value) {
                      scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text('both links copied!'),
                        duration: Duration(seconds: 3),
                      ));
                    });
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    MdiIcons.contentCopy,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class ToolsDialog extends StatefulWidget {
  ToolsDialog({this.userId});

  final userId;

  @override
  _ToolsDialogState createState() => _ToolsDialogState();
}

class _ToolsDialogState extends State<ToolsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Game Tools'),
      content: Container(
        height: 200.0,
        width: 100.0,
        child: ListView(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                HapticFeedback.vibrate();
                slideTransition(
                  context,
                  TheScoreboardScreen(
                    userId: widget.userId,
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.cyan[700],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        MdiIcons.matrix,
                        color: Colors.white,
                      ),
                      Container(
                        width: 120,
                        child: Text(
                          'The Scoreboard',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                HapticFeedback.vibrate();
                slideTransition(
                  context,
                  TeamSelectorScreen(
                    userId: widget.userId,
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.cyan[700],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        MdiIcons.accountSwitch,
                        color: Colors.white,
                      ),
                      Container(
                        width: 120,
                        child: Text(
                          'Team Selector',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                HapticFeedback.vibrate();
                slideTransition(
                  context,
                  DiceAndCoinsScreen(
                    userId: widget.userId,
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.cyan[700],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        MdiIcons.dice3,
                        color: Colors.white,
                      ),
                      Container(
                        width: 120,
                        child: Text(
                          'Dice & Coin',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}

class QuickStartButton extends StatefulWidget {
  final String gameName;
  final String subtitle;
  final Icon icon;
  final int minPlayers;
  final int maxPlayers;
  final bool underConstruction;

  QuickStartButton({
    this.gameName,
    this.subtitle,
    this.icon,
    this.minPlayers,
    this.maxPlayers,
    this.underConstruction = false,
  });

  @override
  _QuickStartButtonState createState() => _QuickStartButtonState();
}

class _QuickStartButtonState extends State<QuickStartButton> {
  bool pressed = false;
  double length = 135;

  unpress() async {
    setState(() {
      pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var numberOfPlayersString = '${widget.minPlayers} player min';
    if (widget.maxPlayers != null) {
      numberOfPlayersString =
          '${widget.minPlayers}-${widget.maxPlayers} players';
    }
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            HapticFeedback.vibrate();
            setState(() {
              pressed = true;
            });
            createGame(context, widget.gameName, '', false, unpress);
          },
          child: Container(
            height: length,
            width: length,
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
                colors: pressed
                    ? [
                        Colors.blue[900],
                        Colors.blue[600],
                      ]
                    : [
                        Colors.blue[800],
                        Colors.blue[400],
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: widget.icon,
                ),
                SizedBox(height: 7),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(100),
                        Colors.blue.withAlpha(50),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(11, 3, 11, 2),
                  child: AutoSizeText(
                    widget.gameName,
                    maxLines: 1,
                    minFontSize: 8,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 1),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withAlpha(0),
                        Colors.white.withAlpha(50),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(12, 3, 10, 2),
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  numberOfPlayersString,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        ),
        widget.underConstruction
            ? Icon(MdiIcons.texture, size: length, color: Colors.amber)
            : Container(),
        widget.underConstruction
            ? Container(
                height: length,
                width: length,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withAlpha(
                    140,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      MdiIcons.accountHardHat,
                      size: 40,
                      color: Colors.amber,
                    ),
                    Text('UNDER\nCONSTRUCTION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                        )),
                  ],
                ),
              )
            : Container(),
      ],
    );
  }
}
