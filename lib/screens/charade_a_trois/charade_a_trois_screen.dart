import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:string_similarity/string_similarity.dart';

import 'package:together/services/services.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/end_game.dart';
import 'package:together/components/buttons.dart';
import 'package:together/components/misc.dart';
import 'package:together/services/firestore.dart';
import 'package:together/components/scroll_view.dart';

import 'charade_a_trois_services.dart';

class CharadeATroisScreen extends StatefulWidget {
  CharadeATroisScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _CharadeATroisScreenState createState() => _CharadeATroisScreenState();
}

class _CharadeATroisScreenState extends State<CharadeATroisScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  TextEditingController wordController;
  List<bool> collapseSampleCharacter = [false, false];
  String characterSelection;
  Timer _timer;
  DateTime _now;
  String errorMessage;
  var T;

  @override
  void initState() {
    super.initState();
    wordController = TextEditingController();
    T = Transactor(sessionId: widget.sessionId);
    setUpGame();
    _timer = Timer.periodic(Duration(milliseconds: 200), (Timer t) {
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

  checkIfVibrate(data) {
    bool isNewVibrateData = false;

    if (isNewVibrateData) {
      HapticFeedback.vibrate();
    }
  }

  setUpGame() async {
    // get session info for locations
    var data = (await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .get())
        .data();
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
    // gets called if time hits 0 or from judge accept/reject button

    // increment team member index, and team index
    data['turn']['teamTurn'] += 1;
    if (data['turn']['teamTurn'] >= data['rules']['numTeams']) {
      data['turn']['teamTurn'] = 0;
    }
    var currentTeamIndex = data['turn']['teamTurn'];
    data['turn']['team${currentTeamIndex}Turn'] += 1;
    if (data['turn']['team${currentTeamIndex}Turn'] >=
        data['teams'][currentTeamIndex]['players'].length) {
      data['turn']['team${currentTeamIndex}Turn'] = 0;
    }

    // reset round score
    data['roundScore'] = 0;
    data['expirationTime'] = null;

    T.transact(data);
  }

  judgmentComplete(data) async {
    // if time is expired, turn should be updated
    if (data['temporaryExpirationTime'] == null) {
      print('turn');
      updateTurn(data);
    }
  }

  updateInternalState(data) async {
    if (_now == null) {
      return;
    }
    var t = _now.difference(data['expirationTime'].toDate()).inSeconds;
    bool doUpdatePhase = false;
    bool changed = false;

    switch (data['internalState']) {
      case 'wordSelection':
        // if timer has expired or words have reached capacity, transition to describe
        if (t > 0 ||
            data['words'].length >= data['rules']['collectionWordLimit']) {
          // supplement words randomly until full
          var words = [
            charadeATroisWords,
            charadeATroisExpressions,
            charadeATroisPeople
          ].expand((x) => x).toList();
          words.shuffle();
          int i = 0;
          while (data['words'].length < data['rules']['collectionWordLimit']) {
            data['words'].add(words[i]);
            i += 1;
          }
          // set piles equal to word list
          data['describePile'] = List.from(data['words']);
          data['describePile'].shuffle();
          data['gesturePile'] = List.from(data['words']);
          data['gesturePile'].shuffle();
          data['oneWordPile'] = List.from(data['words']);
          data['oneWordPile'].shuffle();
          data['expirationTime'] = null;
          doUpdatePhase = true;
        }
        break;
      case 'describe':
      case 'gesture':
      case 'oneWord':
        // if pile is empty, save expiration time, pause for judgment (move to phase afterwards)
        String pile = data['internalState'];
        if (data['${pile}Pile'].length == 0) {
          doUpdatePhase = true;
          if (t < 0) {
            data['temporaryExpirationTime'] = t;
          }
          data['expirationTime'] = null;
        }
        // if judgment is complete and timer *just* expires, update turn
        if (data['expirationTime'] != null) {
          if (t > 0) {
            data['expirationTime'] = null;
            if (['describe', 'gesture', 'oneWord']
                    .contains(data['internalState']) &&
                data['judgeList'].length == 0) {
              updateTurn(data);
            }
            changed = true;
          }
        }
        break;
    }

    if (doUpdatePhase) {
      updatePhase(data);
      changed = true;
    }

    if (changed) {
      T.transact(data);
    }
  }

  updatePhase(data) {
    if (data['internalState'] == 'wordSelection') {
      data['internalState'] = 'describe';
    } else if (data['internalState'] == 'describe') {
      data['internalState'] = 'gesture';
    } else if (data['internalState'] == 'gesture') {
      data['internalState'] = 'oneWord';
    } else {
      // increment scores of winners
      int maxScore = 0;
      data['scores'].forEach((v) {
        if (v > maxScore) {
          maxScore = v;
        }
      });
      data['scores'].asMap().forEach((i, v) {
        if (data['scores'][i] == maxScore) {
          data['teams'][i]['players'].forEach((v) {
            incrementPlayerScore('charadeATrois', v);
          });
        }
      });
      data['internalState'] = 'scoreBoard';
    }
  }

  addWordToList(data) async {
    // check if word already exists
    bool wordAlreadyExists = false;
    data['words'].forEach((v) {
      if (StringSimilarity.compareTwoStrings(v, wordController.text) > 0.7) {
        wordAlreadyExists = true;
      }
    });
    if (!wordAlreadyExists) {
      T.transactCharadeATroisWords(wordController.text);
      setState(() {
        wordController.text = '';
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = 'Similar submission already exists!';
      });
    }
  }

  getWordSelection(data) {
    if (_now == null) {
      return Container();
    }
    var t = _now.difference(data['expirationTime'].toDate()).inSeconds;
    var ms = getMinutesSeconds(-t);
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          Text(
            'Submit words or phrases\nto describe & act out!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          SizedBox(height: 20),
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
          Text(
              '${data['words'].length}/${data['rules']['collectionWordLimit']} submitted'),
          SizedBox(height: 20),
          Container(
            height: 80,
            width: 240,
            padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: TextField(
                maxLines: 1,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: 'write here',
                  isDense: true,
                ),
                controller: wordController,
              ),
            ),
          ),
          SizedBox(height: 10),
          RaisedGradientButton(
            child: Text(
              'Submit',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            onPressed: () {
              addWordToList(data);
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
          errorMessage != null ? SizedBox(height: 5) : Container(),
          errorMessage != null
              ? Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red,
                  ),
                )
              : Container(),
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
    if (data['temporaryExpirationTime'] != null) {
      var ms = getMinutesSeconds(-data['temporaryExpirationTime']);
      timerString =
          '${intToString(ms[0], pad: 2)}:${intToString(ms[1], pad: 2)}';
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
    if (data['temporaryExpirationTime'] != null) {
      data['expirationTime'] = DateTime.now().add(Duration(
        seconds: -data['temporaryExpirationTime'],
      ));
      data['temporaryExpirationTime'] = null;
    } else {
      data['expirationTime'] = DateTime.now()
          .add(Duration(seconds: data['rules']['roundTimeLimit']));
    }

    T.transact(data);
  }

  playerGotWord(data) async {
    // pop word from pile, add words to judgeList
    String pile = data['internalState'];
    var word = data['${pile}Pile'].removeLast();
    data['judgeList'].add(word);

    updateInternalState(data);

    T.transact(data);
  }

  playerSkipsWord(data) async {
    T.transact(data);
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
    if (data['internalState'] == 'scoreBoard') {
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

    HapticFeedback.vibrate();

    await T.transactCharadeATroisJudgeList(data['judgeList']);

    if (data['expirationTime'] == null && data['judgeList'].length == 0) {
      judgmentComplete(data);
    }

    T.transact(data);
  }

  rejectWord(i, data) async {
    data['judgeList'].removeAt(i);

    HapticFeedback.vibrate();

    await T.transactCharadeATroisJudgeList(data['judgeList']);

    if (data['expirationTime'] == null && data['judgeList'].length == 0) {
      judgmentComplete(data);
    }

    T.transact(data);
  }

  acceptAllWords(data) async {
    var currentTeamIndex = data['turn']['teamTurn'];
    data['judgeList'].forEach((v) {
      data['scores'][currentTeamIndex] += 1;
      data['roundScore'] += 1;
    });
    data['judgeList'] = [];

    HapticFeedback.vibrate();

    await T.transactCharadeATroisJudgeList(data['judgeList']);

    if (data['expirationTime'] == null && data['judgeList'].length == 0) {
      judgmentComplete(data);
    }

    T.transact(data);
  }

  getStatus(data) {
    var playerTeamIndex;
    var playerIndexForTeam;
    data['teams'].asMap().forEach((k, v) {
      if (v['players'].contains(widget.userId)) {
        playerTeamIndex = k;
        playerIndexForTeam = v['players'].indexOf(widget.userId);
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
        backgroundColor = Colors.green.withAlpha(150);
        isPlayerTurn = true;
      } else {
        turnString = 'It is your team\'s turn';
        backgroundColor = Colors.green.withAlpha(150);
      }
    }
    String subString = '';
    var currentTeamIndex = data['turn']['teamTurn'];
    var currentPlayerIndex = data['turn']['team${currentTeamIndex}Turn'];
    var currentPlayerId =
        data['teams'][currentTeamIndex]['players'][currentPlayerIndex];
    String playerName = data['playerNames'][currentPlayerId];
    if (data['expirationTime'] == null && data['judgeList'].length != 0) {
      subString = '(waiting on judgement)';
    } else if (data['expirationTime'] == null && !isPlayerTurn) {
      subString = '(waiting for $playerName to start)';
    }

    // player on "next" team is judge
    var nextTeamIndex = data['turn']['teamTurn'] + 1;
    if (nextTeamIndex >= data['rules']['numTeams']) {
      nextTeamIndex = 0;
    }
    List<Widget> words = [];
    List<Widget> reject = [];
    List<Widget> accept = [];
    data['judgeList'].asMap().forEach((i, v) {
      words.add(
        Container(
          height: 30,
          width: 100,
          child: Center(
            child: AutoSizeText(
              v,
              maxLines: 2,
            ),
          ),
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
      accept.add(
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
            Column(children: accept),
          ],
        ),
        SizedBox(height: 10),
        RaisedGradientButton(
          child: Text('accept all'),
          width: 100,
          height: 30,
          gradient: LinearGradient(
            colors: [
              Colors.green[600],
              Colors.green[400],
            ],
          ),
          onPressed: () {
            acceptAllWords(data);
          },
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
                fontSize: 22,
              ),
            ),
            data['expirationTime'] != null
                ? Text('Waiting for player to finish...')
                : data['judgeList'].length == 0
                    ? Container()
                    : judgeWordListWidget,
          ],
        ),
      );
    }

    return Container(
      width: 180,
      height: 70,
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
                fontSize: 20,
              ),
            ),
            subString == '' ? Container() : SizedBox(height: 10),
            subString == ''
                ? Container()
                : AutoSizeText(
                    subString,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  getStats(data) {
    String pile = data['internalState'];
    if (pile == 'scoreBoard') {
      pile = 'oneWord';
    }
    return Container(
      width: 190,
      height: 80,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Round\nscore:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cards to\njudge:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 5),
              Text(
                data['judgeList'].length.toString(),
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cards left\nin pile:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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

  getTurn(data) {
    var currentTeamIndex = data['turn']['teamTurn'];
    var currentPlayerIndex = data['turn']['team${currentTeamIndex}Turn'];
    var currentPlayerId =
        data['teams'][currentTeamIndex]['players'][currentPlayerIndex];

    var nextTeamIndex = currentTeamIndex + 1;
    if (nextTeamIndex >= data['rules']['numTeams']) {
      nextTeamIndex = 0;
    }
    var nextPlayerIndex = data['turn']['team${nextTeamIndex}Turn'];
    var currentJudgeId =
        data['teams'][nextTeamIndex]['players'][nextPlayerIndex];

    List<Widget> teams = [SizedBox(width: 15)];
    // iterate over teams, generate a column for each. indicate if current player or judge
    for (int i = 0; i < data['teams'].length; i++) {
      List<Widget> playerNames = [
        Text('Team ${i + 1}',
            style: TextStyle(
              fontSize: 10,
              color: currentTeamIndex == i ? Colors.blue : Colors.grey,
            ))
      ];
      data['teams'][i]['players'].forEach((v) {
        String playerName = data['playerNames'][v];
        if (widget.userId == v) {
          playerName = playerName + ' (you)';
        }
        if (currentPlayerId == v) {
          playerName = '> ' + playerName + ' <';
        }
        if (currentJudgeId == v) {
          playerName = playerName + ' (J)';
        }
        playerNames.add(Text(
          playerName,
          style: TextStyle(
            fontSize: 11,
            color: currentPlayerId == v
                ? Colors.blue
                : currentJudgeId == v
                    ? Colors.amber[800]
                    : Theme.of(context).highlightColor,
          ),
        ));
      });
      teams.add(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: playerNames,
        ),
      );
      teams.add(SizedBox(width: 15));
    }
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: teams,
      ),
    );
  }

  getGameboard(data) {
    // if it is not your turn, should be "other team is playing!", "waiting for XX to start!"
    if (_now == null) {
      return Container();
    }
    var playerTeamIndex;
    var playerIndexForTeam;
    data['teams'].asMap().forEach((k, v) {
      if (v['players'].contains(widget.userId)) {
        playerTeamIndex = k;
        playerIndexForTeam = v['players'].indexOf(widget.userId);
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

    return TogetherScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            getPhaseTitle(data),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getStatus(data),
                SizedBox(width: 10),
                Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Theme.of(context).highlightColor,
                      ),
                    ),
                    padding: EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Room code:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          widget.roomCode,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getTimer(data),
                SizedBox(width: 10),
                getTurn(data),
              ],
            ),
            SizedBox(height: 20),
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
                            : () {},
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
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  getScoreboard(data) {
    List<Widget> scores = [];
    int maxScore = 0;
    data['scores'].forEach((v) {
      if (v > maxScore) {
        maxScore = v;
      }
    });
    data['scores'].asMap().forEach((i, v) {
      List<Widget> members = [];
      data['teams'][i]['players'].forEach((v) {
        members.add(Text(data['playerNames'][v]));
      });
      bool isWinner = false;
      if (data['scores'][i] == maxScore) {
        isWinner = true;
      }
      scores.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isWinner
                ? Icon(
                    MdiIcons.crown,
                    color: Colors.amber,
                    size: 50,
                  )
                : Container(),
            isWinner ? SizedBox(width: 10) : Container(),
            Column(
              children: [
                Text(
                  'Team ${i + 1}',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                PageBreak(width: 30),
                Column(children: members),
                SizedBox(height: 20),
              ],
            ),
            SizedBox(width: 20),
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).highlightColor),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['scores'][i].toString(),
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                    Text('pts'),
                  ],
                ),
              ),
            ),
            isWinner ? SizedBox(width: 10) : Container(),
            isWinner
                ? Icon(
                    MdiIcons.crown,
                    color: Colors.amber,
                    size: 50,
                  )
                : Container(),
          ],
        ),
      );
    });
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Scoreboard',
            style: TextStyle(
              fontSize: 30,
            ),
          ),
          PageBreak(width: 100),
          SizedBox(height: 20),
          Column(children: scores),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Charáde à Trois',
                ),
              ),
              body: Container(),
            );
          }
          // all data for all components
          DocumentSnapshot snapshotData = snapshot.data;
          var data = snapshotData.data();
          if (data == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Charáde à Trois',
                ),
              ),
              body: Container(),
            );
          }
          checkIfExit(data, context, widget.sessionId, widget.roomCode);
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
                'Charáde à Trois',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
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
                            .contains(data['internalState']) ||
                        data['judgeList'].length != 0
                    ? getGameboard(data)
                    : getScoreboard(data),
          );
        });
  }
}
