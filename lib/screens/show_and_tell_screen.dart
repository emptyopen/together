import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'lobby_screen.dart';
import 'package:together/components/end_game.dart';
import 'package:together/components/buttons.dart';
import 'package:together/components/misc.dart';

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

  updateTurn(data) async {
    // increment team member index, and team index
    print('will go to next team/player');
    data['roundScore'] = 0;
    // LEAVE THIS FOR LAST
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  updateInternalState(data) async {
    // timer expires, OR a pile runs out of cards
    // timer: wordSelection to describe, otherwise update team
    bool updateState = false;

    // if pile runs out of cards, save the remaining time to be used for the next phase by the same team
    String pile = data['internalState'];
    if (data['${pile}Pile'].length == 0) {
      updateState = true;
    }
    // if timer expires, if state is wordSelection, change
    var t = _now.difference(data['expirationTime'].toDate()).inSeconds;
    if (t > 0) {
      // if (now - expiration time) is negative, set it to null
      data['expirationTime'] = null;
      if (data['internalState'] == 'wordSelection') {
        updateState = true;
      } else {
        updateTurn(data);
      }
    }

    if (updateState) {
      if (data['internalState'] == 'wordSelection') {
        data['internalState'] = 'describe';
      } else if (data['internalState'] == 'describe') {
        data['internalState'] = 'gesture';
      } else if (data['internalState'] == 'gesture') {
        data['gesture'] = 'oneWord';
      } else {
        data['internalState'] = 'scoreBoard';
      }
      await Firestore.instance
          .collection('sessions')
          .document(widget.sessionId)
          .setData(data);
    }
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
        color: word == 'NONE LEFT'
            ? Colors.grey
            : Colors.indigoAccent.withAlpha(180),
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

  playerGotWord(data) async {
    // pop word from pile, add words to judgeList
    String pile = data['internalState'];
    var word = data['${pile}Pile'].removeLast();
    data['judgeList'].add(word);

    updateInternalState(data);
    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  playerSkipsWord(data) async {
    // pop word from pile, add words to judgeList
    String pile = data['internalState'];
    var word = data['${pile}Pile'].removeLast();
    data['${pile}Pile'].insert(0, word);

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
                playerGotWord(data);
              },
              height: 60,
              width: 120,
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.green[600],
                  Colors.green[300],
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
                playerSkipsWord(data);
              },
              height: 60,
              width: 120,
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.red[700],
                  Colors.red[400],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  getPhaseTitle(data) {
    // all players should see timer
    // all players should see number completed
    var phase = 'describe';
    var emoticon = MdiIcons.commentText;
    if (data['internalState'] == 'gesture') {
      phase = 'gesture';
      emoticon = MdiIcons.humanHandsup;
    }
    if (data['internalState'] == 'oneWord') {
      phase = 'one word';
      emoticon = MdiIcons.flaskEmptyOutline;
    }
    return Column(children: [
      PageBreak(width: 100),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emoticon,
            color: Theme.of(context).highlightColor,
            size: 50,
          ),
          SizedBox(width: 30),
          Text(
            phase,
            style: TextStyle(
              fontSize: 38,
            ),
          ),
          SizedBox(width: 30),
          Icon(
            emoticon,
            color: Theme.of(context).highlightColor,
            size: 50,
          ),
        ],
      ),
      Text(
        'phase',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      SizedBox(height: 10),
      PageBreak(width: 100),
    ]);
  }

  acceptWord(i, data) async {
    data['judgeList'].removeAt(i);
    // increment score
    var currentTeamIndex = data['turn']['teamTurn'];
    data['scores'][currentTeamIndex] += 1;
    data['roundScore'] += 1;

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  rejectWord(i, data) async {
    var word = data['judgeList'].removeAt(i);
    String pile = data['internalState'];
    data['${pile}Pile'].insert(0, word);

    print(word);

    await Firestore.instance
        .collection('sessions')
        .document(widget.sessionId)
        .setData(data);
  }

  getStatus(data) {
    var playerTeamIndex;
    var playerIndexForTeam;
    data['teams'].forEach((k, v) {
      if (v.contains(widget.userId)) {
        playerTeamIndex = int.parse(k[k.length - 1]);
        playerIndexForTeam = v.indexOf(widget.userId);
      }
    });
    String turnString = '';
    Color backgroundColor = Colors.grey;
    bool isPlayerTurn = false;
    if (data['turn']['teamTurn'] != playerTeamIndex) {
      turnString = 'Waiting for your team\'s turn...';
    } else {
      // it is player team's turn
      if (data['turn']['team${playerTeamIndex}Turn'] == playerIndexForTeam) {
        turnString = 'It is your turn';
        backgroundColor = Colors.green.withAlpha(100);
        isPlayerTurn = true;
      } else {
        turnString = 'It is your team\'s turn';
        backgroundColor = Colors.green.withAlpha(100);
      }
    }
    String subString = '';
    if (data['expirationTime'] == null && data['judgeList'].length != 0) {
      subString = '(waiting on judgement of last round)';
    } else if (data['expirationTime'] == null && !isPlayerTurn) {
      subString = '(waiting for XX to start)';
    }

    // player on "next" team is judge
    var nextTeamIndex = data['turn']['teamTurn'] + 1;
    if (nextTeamIndex >= data['rules']['numTeams']) {
      nextTeamIndex = 0;
    }
    List<Widget> words = [];
    List<Widget> reject = [];
    List<Widget> approve = [];
    data['judgeList'].asMap().forEach((i, v) {
      words.add(
        Container(
          height: 30,
          child: Center(child: Text(v)),
        ),
      );
      reject.add(
        Container(
          height: 30,
          child: GestureDetector(
            onTap: () {
              rejectWord(i, data);
            },
            child: Icon(
              MdiIcons.skull,
              color: Colors.red,
            ),
          ),
        ),
      );
      approve.add(
        Container(
          height: 30,
          child: GestureDetector(
            onTap: () {
              acceptWord(i, data);
            },
            child: Icon(
              MdiIcons.check,
              color: Colors.green,
            ),
          ),
        ),
      );
    });
    var judgeWordListWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 10),
        Text('Judge these:'),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: words),
            Column(children: reject),
            Column(children: approve),
          ],
        ),
        SizedBox(height: 10),
        RaisedGradientButton(
          child: Text('approve all'),
          width: 100,
          height: 30,
        ),
      ],
    );

    if (playerTeamIndex == nextTeamIndex &&
        playerIndexForTeam == data['turn']['team${nextTeamIndex}Turn']) {
      return Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(100),
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You are the judge!',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            data['judgeList'].length == 0 ? Container() : judgeWordListWidget,
          ],
        ),
      );
    }

    return Container(
      width: 230,
      height: 80,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(10),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              turnString,
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            subString == '' ? Container() : SizedBox(height: 10),
            subString == ''
                ? Container()
                : Text(
                    subString,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  getStats(data) {
    String pile = data['internalState'];
    return Container(
      width: 180,
      height: 80,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Round\nscore:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 5),
              Text(
                data['roundScore'].toString(),
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ],
          ),
          SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remaining\ncards:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 5),
              Text(
                data['${pile}Pile'].length.toString(),
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
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
    if (data['turn']['teamTurn'] == playerTeamIndex) {
      // it is player team's turn
      if (data['turn']['team${playerTeamIndex}Turn'] == playerIndexForTeam) {
        isPlayerTurn = true;
      }
    }

    // previous words need to be judged by "previous" player for next team
    bool previousWordsJudged = false;
    if (data['judgeList'].length == 0) {
      previousWordsJudged = true;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getPhaseTitle(data),
          SizedBox(height: 20),
          getStatus(data),
          SizedBox(height: 20),
          getTimer(data),
          SizedBox(height: 10),
          getStats(data),
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
                      onPressed: previousWordsJudged
                          ? () {
                              startRound(data);
                            }
                          : null,
                      height: 60,
                      width: 100,
                      gradient: LinearGradient(
                        colors: previousWordsJudged
                            ? [
                                Colors.blue,
                                Colors.blueAccent,
                              ]
                            : [
                                Colors.grey,
                                Colors.grey,
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
                  'Show & Tell',
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
                  'Show & Tell',
                ),
              ),
              body: Container(),
            );
          }
          checkIfExit(data);
          checkIfVibrate(data);
          // update game state
          if (data['expirationTime'] != null) {
            updateInternalState(data);
          }
          return Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                'Show & Tell',
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
