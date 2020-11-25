import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:async';
import 'package:string_similarity/string_similarity.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flushbar/flushbar.dart';

import 'package:together/components/misc.dart';
import 'package:together/components/buttons.dart';
import 'package:together/components/scroll_view.dart';
import 'package:together/services/services.dart';
import 'package:together/services/firestore.dart';
import 'package:together/help_screens/help_screens.dart';
import 'package:together/components/end_game.dart';
import 'package:together/constants/values.dart';

import 'samesies_services.dart';

class SamesiesScreen extends StatefulWidget {
  SamesiesScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _SamesiesScreenState createState() => _SamesiesScreenState();
}

class _SamesiesScreenState extends State<SamesiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  TextEditingController messageController;
  DateTime _now;
  var T;
  final _controller = TextEditingController();
  int activeController;
  FocusNode myFocusNode;
  double matchFactor = 0.8;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    myFocusNode = FocusNode();
    T = Transactor(sessionId: widget.sessionId);
    setUpGame();
    Timer.periodic(Duration(milliseconds: 300), (Timer t) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    _controller.dispose();
    myFocusNode.dispose();
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

  getStatus(data) {
    // can either be
    // title: waiting to start
    // title: playing
    bool isRunning = data['expirationTime'] != null;
    String word = '';
    data['teams'].asMap().forEach((i, v) {
      if (data['teams'][i]['players'].contains(widget.userId)) {
        word = data['teams'][i]['words'][data['level']];
      }
    });
    var level = 'Level ${levelToNumber(data)}';
    var title = isRunning ? word.toUpperCase() : 'Waiting...';
    var ms = [0, 0];
    if (isRunning && _now != null) {
      ms = getMinutesSeconds(
          -_now.difference(data['expirationTime'].toDate()).inSeconds);
    }
    var subtitle = !isRunning
        ? '--:--'
        : '${intToString(ms[0], pad: 2)}:${intToString(ms[1], pad: 2)}';
    return Container(
      width: 200,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).dialogBackgroundColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            level,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          SizedBox(height: 5),
          Text(subtitle,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              )),
        ],
      ),
    );
  }

  getRoomCode(data) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Theme.of(context).highlightColor,
          ),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        padding: EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Room code:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              widget.roomCode,
              style: TextStyle(
                fontSize: 22,
              ),
            ),
          ],
        ));
  }

  getTimerBar(data) {
    var width = MediaQuery.of(context).size.width;
    double remainingPercentage = 0;
    if (data['expirationTime'] != null && _now != null) {
      remainingPercentage =
          -_now.difference(data['expirationTime'].toDate()).inSeconds /
              data['rules']['roundTimeLimit'];
    }
    return remainingPercentage > 0
        ? Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 5,
              width: remainingPercentage * width,
              decoration: BoxDecoration(
                color: gameColors[samesiesString],
              ),
            ),
          )
        : Container(height: 5);
  }

  getSubmissionProgress(data) {
    List<Widget> submissionWidgets = [SizedBox(width: 10)];
    int limit = getSubmissionLimit(data);
    for (int i = 0; i < limit; i++) {
      submissionWidgets.add(Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
          color: data['playerWords'][widget.userId].length > i
              ? gameColors[samesiesString]
              : Theme.of(context).highlightColor.withAlpha(5),
        ),
        height: 20,
        width: 20,
      ));
      submissionWidgets.add(SizedBox(width: 10));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: submissionWidgets,
    );
  }

  playerReady(data) async {
    data['ready'][widget.userId] = true;

    // if all players are ready, start the timer
    bool allReady = true;
    data['ready'].forEach((i, v) {
      if (!v) {
        allReady = false;
      }
    });
    if (allReady) {
      // clear previous results
      data['teams'].asMap().forEach((i, v) {
        data['teams'][i]['results'] = [];
      });
      data['expirationTime'] = DateTime.now()
          .add(Duration(seconds: data['rules']['roundTimeLimit']));
    }
    T.transact(data);
  }

  getTeamResults(teamIndex, data) {
    // TODO: make this swipable for different teams, initialized per team
    List<Widget> player1Words = [
      Text(
        data['playerNames'][data['teams'][teamIndex]['players'][0]],
        style: TextStyle(fontSize: 22),
      ),
      PageBreak(width: 40),
    ];
    List<Widget> player2Words = [
      Text(
        data['playerNames'][data['teams'][teamIndex]['players'][1]],
        style: TextStyle(fontSize: 22),
      ),
      PageBreak(width: 40),
    ];
    // TODO: add third if necessary
    List<Widget> points = [
      Text(
        'pts',
        style: TextStyle(fontSize: 22),
      ),
      PageBreak(width: 20),
    ];
    var width = MediaQuery.of(context).size.width;
    data['teams'][teamIndex]['results'].forEach((v) {
      player1Words.add(Container(
          height: 25,
          width: width * 0.25,
          child: Center(
            child: AutoSizeText(
              v['words'][0],
              textAlign: TextAlign.center,
              minFontSize: 6,
              style: TextStyle(
                  fontSize: 20,
                  color: v['score'] > 0
                      ? v['score'] > 2
                          ? gameColors[samesiesString]
                          : Theme.of(context).highlightColor
                      : Colors.grey),
              maxLines: 2,
            ),
          )));
      player2Words.add(Container(
          height: 25,
          width: width * 0.25,
          child: Center(
            child: AutoSizeText(
              v['words'][1],
              textAlign: TextAlign.center,
              minFontSize: 6,
              style: TextStyle(
                  fontSize: 20,
                  color: v['score'] > 0
                      ? v['score'] > 2
                          ? gameColors[samesiesString]
                          : Theme.of(context).highlightColor
                      : Colors.grey),
              maxLines: 2,
            ),
          )));
      points.add(Container(
        height: 25,
        child: AutoSizeText(
          v['score'].toString(),
          maxLines: 1,
          style: TextStyle(
            fontSize: 22,
            color: v['score'] > 0
                ? v['score'] > 2
                    ? gameColors[samesiesString]
                    : Theme.of(context).highlightColor
                : Colors.grey,
          ),
        ),
      ));
    });
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Column(children: player1Words),
        ),
        SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Column(
            children: player2Words,
          ),
        ),
        SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Column(
            children: points,
          ),
        ),
      ],
    );
  }

  getRoundSummary(data) {
    bool complete = false;
    if (data['state'] == 'scoreboard') {
      complete = true;
    }
    int score = 0;
    // TODO: multiple
    data['teams'][0]['results'].forEach((v) {
      score += v['score'];
    });
    List<Widget> teamResultWidgets = [
      Text(
          complete
              ? 'You got knocked out on level ${levelToNumber(data)}'
              : 'Level ${levelToNumber(data) - 1} complete!',
          style: TextStyle(
            fontSize: 22,
            color: gameColors[samesiesString],
          )),
      SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Score: $score',
              style: TextStyle(
                fontSize: 18,
              )),
          SizedBox(width: 10),
          Text(
              '(needed ${complete ? requiredScoreForLevel(data['level']) : requiredScoreForPreviousLevel(data['level'])})',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              )),
        ],
      ),
      SizedBox(height: 10),
    ];
    data['teams'].asMap().forEach((i, v) {
      teamResultWidgets.add(getTeamResults(i, data));
      teamResultWidgets.add(SizedBox(height: 10));
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: teamResultWidgets,
    );
  }

  getPrepare(data) {
    // check if player is ready, show who is ready
    List<Widget> playerStatuses = [];
    data['playerIds'].forEach((v) {
      playerStatuses.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data['playerNames'][v]),
            SizedBox(width: 5),
            data['ready'][v]
                ? Icon(MdiIcons.checkBoxOutline, color: Colors.green)
                : Icon(MdiIcons.checkboxBlank, color: Colors.grey),
          ],
        ),
      );
    });

    bool roundSummaryExists = false;
    data['teams'].forEach((v) {
      if (v['results'].length > 0) {
        roundSummaryExists = true;
      }
    });

    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            roundSummaryExists ? getRoundSummary(data) : Container(width: 0),
            Container(
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: playerStatuses,
              ),
            ),
            SizedBox(height: 15),
            RaisedGradientButton(
              height: 60,
              width: 190,
              child: Text('Ready!', style: TextStyle(fontSize: 35)),
              gradient: LinearGradient(
                colors: !data['ready'][widget.userId]
                    ? [
                        gameColors[samesiesString],
                        gameColors[samesiesString].withAlpha(100),
                      ]
                    : [
                        Colors.grey,
                        Colors.grey,
                      ],
              ),
              onPressed: !data['ready'][widget.userId]
                  ? () {
                      playerReady(data);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  storeTeamResults(teamIndex, data) {
    int twoPlayerPairScore = 2;
    int threePlayerPairScore = 1;
    int threePlayerTripletScore = 3;
    int teamSize = data['teams'][teamIndex]['players'].length;

    // if team has 2 players
    if (teamSize == 2) {
      // iterate over one players score, check if it exists in the other one
      var player1Id = data['teams'][teamIndex]['players'][0];
      var player2Id = data['teams'][teamIndex]['players'][1];
      List player1Words = List.of(data['playerWords'][player1Id]);
      List player2Words = List.of(data['playerWords'][player2Id]);
      List unmatchedPlayer1Words = [];
      List matchedPlayer2Words = [];
      player1Words.forEach((player1Word) {
        bool matchFound = false;
        player2Words.forEach((player2Word) {
          if (StringSimilarity.compareTwoStrings(
                  player1Word.toLowerCase(), player2Word.toLowerCase()) >
              matchFactor) {
            data['teams'][teamIndex]['results'].add({
              'words': [player1Word, player2Word],
              'similarity':
                  StringSimilarity.compareTwoStrings(player1Word, player2Word),
              'score': twoPlayerPairScore
            });
            matchedPlayer2Words.add(player2Word);
            matchFound = true;
          }
        });
        if (!matchFound) {
          unmatchedPlayer1Words.add(player1Word);
        }
      });
      player2Words
          .removeWhere((element) => matchedPlayer2Words.contains(element));
      for (int i = 0; i < unmatchedPlayer1Words.length; i++) {
        data['teams'][teamIndex]['results'].add({
          'words': [unmatchedPlayer1Words[i], player2Words[i]],
          'similarity': StringSimilarity.compareTwoStrings(
              unmatchedPlayer1Words[i], player2Words[i]),
          'score': 0
        });
      }
    }

    // if team has 3 players
    else {}

    // stores words lined up, with scores:
    // [knife, knife, 2]
    // [counter, counter, 2]
    // [food, food, 2]
    // [tile, microwave, 0]
    // ...
    return data['teams'][teamIndex]['results'];
  }

  teamsAllPass(data) {
    // for each team, check if all teams pass
    bool allTeamsPass = true;
    data['teams'].asMap().forEach((i, v) {
      storeTeamResults(i, data);
      int score = 0;
      data['teams'][i]['results'].forEach((result) {
        score += result['score'];
      });
      if (score >= requiredScoreForLevel(data['level'])) {
        print(
            'score $score passes required score ${requiredScoreForLevel(data['level'])}');
      } else {
        allTeamsPass = false;
      }
    });

    if (allTeamsPass) {
      return true;
    }
    return false;
  }

  submitWord(data) async {
    // check word isn't already submitted
    bool isDuplicateWord = false;
    data['playerWords'][widget.userId].forEach((v) {
      if (StringSimilarity.compareTwoStrings(_controller.text, v) >
          matchFactor) {
        Flushbar(
          flushbarPosition: FlushbarPosition.TOP,
          title: 'Similar word already submitted!',
          message: 'Try another word.',
          duration: Duration(seconds: 3),
        ).show(context);
        isDuplicateWord = true;
      }
    });
    if (isDuplicateWord) {
      return;
    }

    HapticFeedback.vibrate();

    data['playerWords'][widget.userId].add(_controller.text);

    // if all players are done, move to "comparison" page
    bool allPlayersSubmitted = true;
    int limit = getSubmissionLimit(data);
    data['playerIds'].forEach((v) {
      if (data['playerWords'][v].length < limit) {
        allPlayersSubmitted = false;
      }
    });
    if (allPlayersSubmitted) {
      print('all players submitted');
      // check if all teams match sufficiently
      if (teamsAllPass(data)) {
        incrementLevel(data);
        // reset playerWords and ready states
        data['playerIds'].forEach((v) {
          data['playerWords'][v] = [];
          data['ready'][v] = false;
        });
      } else {
        data['state'] = 'scoreboard';
      }
      data['expirationTime'] = null;
    }

    T.transact(data);
    setState(() {
      _controller.text = '';
    });
    myFocusNode.requestFocus();
  }

  getSubmit(data) {
    var width = MediaQuery.of(context).size.width;

    // if player is done, show awaiting
    if (data['playerWords'][widget.userId].length >= 10) {
      List<Widget> playerStatuses = [
        Text(
          'Waiting for players...',
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 20),
      ];
      data['playerIds'].forEach((v) {
        playerStatuses.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data['playerNames'][v]),
              SizedBox(width: 5),
              data['playerWords'][v].length >= 10
                  ? Icon(MdiIcons.checkBoxOutline, color: Colors.green)
                  : Icon(MdiIcons.checkboxBlank, color: Colors.grey),
            ],
          ),
        );
      });
      return Container(
        width: 0.8 * width,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Column(children: playerStatuses),
          ],
        ),
      );
    }

    // otherwise, get submit
    return Container(
      width: 0.8 * width,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).dialogBackgroundColor,
      ),
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              textInputAction: TextInputAction.send,
              onSubmitted: (s) {
                submitWord(data);
              },
              autofocus: true,
              focusNode: myFocusNode,
              style: TextStyle(fontSize: 16),
              controller: _controller,
              textAlign: TextAlign.center,
              maxLines: 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          SizedBox(height: 10),
          RaisedGradientButton(
            height: 40,
            width: 160,
            onPressed: () {
              submitWord(data);
            },
            child: Text('Submit (or hit enter)'),
            gradient: LinearGradient(colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor
            ]),
          ),
        ],
      ),
    );
  }

  getScoreboard(data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getRoundSummary(data),
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

  getGameboard(data) {
    return TogetherScrollView(
      child: Column(
        mainAxisAlignment: data['expirationTime'] != null
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getStatus(data),
              SizedBox(width: 10),
              getRoomCode(data),
            ],
          ),
          SizedBox(height: 5),
          getTimerBar(data),
          SizedBox(height: 5),
          !playerIsDoneSubmitting(widget.userId, data) &&
                  allPlayersAreReady(data)
              ? getSubmissionProgress(data)
              : Container(),
          SizedBox(height: 5),
          !allPlayersAreReady(data) ? getPrepare(data) : getSubmit(data),
          SizedBox(height: 15),
          widget.userId == data['leader']
              ? EndGameButton(
                  sessionId: widget.sessionId,
                  fontSize: 14,
                  height: 30,
                  width: 100,
                )
              : Container(),
          SizedBox(height: 15),
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
                'Samesies',
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
                'Samesies',
              ),
            ),
            body: Container(),
          );
        }
        checkIfExit(data, context, widget.sessionId, widget.roomCode);
        checkIfVibrate(data);
        return Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                'Samesies',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return SamesiesScreenHelp();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: data['state'] == 'scoreboard'
                ? getScoreboard(data)
                : getGameboard(data));
      },
    );
  }
}
