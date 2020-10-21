import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'lobby_screen.dart';
import 'package:together/components/end_game.dart';
import 'package:together/components/buttons.dart';

class ShowAndTellScreen extends StatefulWidget {
  ShowAndTellScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _ShowAndTellScreenState createState() => _ShowAndTellScreenState();
}

class _ShowAndTellScreenState extends State<ShowAndTellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  TextEditingController wordController;
  List<bool> collapseSampleCharacter = [false, false];
  String characterSelection;
  Timer _timer;
  DateTime _now;
  // vibrate states

  @override
  void initState() {
    super.initState();
    wordController = TextEditingController();
    setUpGame();
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    wordController.dispose();
    super.dispose();
  }

  checkIfExit(data) async {
    // run async func to check if game is over, or back to lobby or deleted (main menu)
    if (data == null) {
      // navigate to main menu
      Navigator.of(context).pop();
    } else if (data['state'] == 'lobby') {
      // I DON'T KNOW WHY WE NEED THIS BUT OTHERWISE WE GET DEBUG LOCKED ISSUES
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .setData(data);
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
    bool isNewVibrateData = false;

    if (isNewVibrateData) {
      HapticFeedback.vibrate();
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

  String intToString(int i, {int pad: 0}) {
    var str = i.toString();
    var paddingToAdd = pad - str.length;
    return (paddingToAdd > 0)
        ? "${new List.filled(paddingToAdd, '0').join('')}$i"
        : str;
  }

  getMinutesSeconds(int seconds) {
    var m = seconds ~/ 60;
    var s = seconds - m * 60;
    return [m, s];
  }

  updateInternalState(data) async {
    // this will be called every time the timer expires
    // - wordSelection to describe
    // - describe:
    //
    String nextState = data['internalState'];
    if (data['internalState'] == 'wordSelection') {
      ---
    }
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .updateData({
      'internalState': nextState,
      'expirationTime': null,
    });
  }

  getWordSelection(data) {
    var t = _now.difference(data['expirationTime'].toDate()).inSeconds;
    var ms = getMinutesSeconds(-t);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          t < 0
              ? Text(
                  '${intToString(ms[0], pad: 2)}:${intToString(ms[1], pad: 2)}',
                  style: TextStyle(
                    fontSize: 30,
                  ),
                )
              : Text(''),
          SizedBox(height: 5),
          Text(
            'remaining to submit words!',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 40,
            width: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: TextField(
              maxLines: null,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'description here',
              ),
              style: TextStyle(
                fontSize: 16,
              ),
              controller: wordController,
            ),
          ),
          SizedBox(height: 10),
          RaisedGradientButton(
            child: Text(
              'Submit',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            onPressed: () {
              print('hey');
            },
            height: 40,
            width: 140,
            gradient: LinearGradient(
              colors: <Color>[
                Colors.blue,
                Colors.blueAccent,
              ],
            ),
          ),
          SizedBox(height: 20),
          widget.userId == data['leader']
              ? EndGameButton(
                  sessionId: widget.sessionId,
                  fontSize: 14,
                  height: 30,
                  width: 100,
                )
              : Container(),
        ],
      ),
    );
  }

  getTimer(data) {
    String timerString = '--:--';
    bool isRunning = false;
    if (data['expirationTime'] != null) {
      var t = _now.difference(data['expirationTime'].toDate()).inSeconds;
      var ms = getMinutesSeconds(-t);
      timerString =
          '${intToString(ms[0], pad: 2)}:${intToString(ms[1], pad: 2)}';
      isRunning = true;
    }
    return Container(
      height: 50,
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          timerString,
          style: TextStyle(
            fontSize: 30,
            color: isRunning ? Theme.of(context).highlightColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  getWord(data) {
    String word = '-';
    bool isRunning = false;
    String pile = data['internalState'];
    if (data['${pile}Pile'].length == 0) {
      word = 'NONE LEFT';
    } else if (data['expirationTime'] != null) {
      word = data['${pile}Pile'].last;
      isRunning = true;
    }
    return Container(
      height: 70,
      width: 240,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(15),
      child: Center(
        child: AutoSizeText(
          word,
          maxLines: 2,
          style: TextStyle(
            fontSize: 30,
            color: isRunning ? Theme.of(context).highlightColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  startRound(data) async {
    data['expirationTime'] =
        DateTime.now().add(Duration(seconds: data['rules']['roundTimeLimit']));

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getButtons(data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedGradientButton(
              child: Text(
                'Got it!',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              onPressed: () {
                print('hey');
              },
              height: 60,
              width: 120,
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.green[800],
                  Colors.green[500],
                ],
              ),
            ),
            SizedBox(width: 20),
            RaisedGradientButton(
              child: Text(
                'Skip',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              onPressed: () {
                print('hey');
              },
              height: 60,
              width: 120,
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.red[900],
                  Colors.red[700],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  getGameboard(data) {
    // if it is not your turn, should be "other team is playing!", "waiting for XX to start!"
    var playerTeamIndex;
    var playerIndexForTeam;
    data['teams'].forEach((k, v) {
      if (v.contains(widget.userId)) {
        playerTeamIndex = int.parse(k[k.length - 1]);
        playerIndexForTeam = v.indexOf(widget.userId);
      }
    });
    bool isPlayerTurn = false;
    String stateString = 'default state';
    if (data['turn']['teamTurn'] != playerTeamIndex) {
      stateString = 'Waiting for your team\'s turn...';
    } else {
      // it is player team's turn
      if (data['turn']['team${playerTeamIndex}Turn'] == playerIndexForTeam) {
        stateString = 'It is your turn';
        isPlayerTurn = true;
      } else {
        stateString = 'It is your teammates turn';
      }
    }

    // all players should see timer
    // all players should see number completed
    // var internal = Text('describe');
    // if (data['internalState'] == 'gesture') {
    //   internal = Text('gesture');
    // }
    // if (data['internalState'] == 'oneWord') {
    //   internal = Text('oneWord');
    // }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(stateString),
          SizedBox(height: 20),
          getTimer(data),
          SizedBox(height: 20),
          data['expirationTime'] == null || !isPlayerTurn
              ? Container()
              : Column(
                  children: [
                    getWord(data),
                    SizedBox(height: 20),
                    getButtons(data),
                  ],
                ),
          data['expirationTime'] == null && isPlayerTurn
              ? Column(
                  children: [
                    RaisedGradientButton(
                      child: Text(
                        'GO!',
                        style: TextStyle(fontSize: 32, color: Colors.white),
                      ),
                      onPressed: () {
                        startRound(data);
                      },
                      height: 60,
                      width: 100,
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.blue,
                          Colors.blueAccent,
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                )
              : Container(),
          widget.userId == data['leader']
              ? EndGameButton(
                  sessionId: widget.sessionId,
                  fontSize: 14,
                  height: 30,
                  width: 100,
                )
              : Container(),
        ],
      ),
    );
  }

  getScoreboard(data) {
    return Column(
      children: [
        Text('Scoreboard'),
      ],
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
                  'Plot Twist',
                ),
              ),
              body: Container(),
            );
          }
          // all data for all components
          DocumentSnapshot snapshotData = snapshot.data;
          var data = snapshotData.data;
          if (data == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Plot Twist',
                ),
              ),
              body: Container(),
            );
          }
          checkIfExit(data);
          checkIfVibrate(data);
          // update game state
          var t = _now.difference(data['expirationTime'].toDate()).inSeconds;
          if (t > 0) {
            updateInternalState(data);
          }
          return Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                'Plot Twist',
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
                          return PlotTwistScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: data['internalState'] == 'wordSelection'
                ? getWordSelection(data)
                : ['describe', 'gesture', 'oneWord']
                        .contains(data['internalState'])
                    ? getGameboard(data)
                    : getScoreboard(data),
          );
        });
  }
}
