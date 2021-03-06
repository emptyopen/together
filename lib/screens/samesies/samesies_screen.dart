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
  bool isUpdating = false;
  bool submittingWord = false;

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

  getLevelProgress(data) {
    double progressBallLength = 7;
    int level = levelToNumber(data);
    List<Widget> barWidgets = [];
    List levelList = getLevelList(data);
    // easy, medium, etc cutoffs for respective color
    int mediumCutoffIndex = levelList.indexWhere((x) => x.contains('medium'));
    int hardCutoffIndex = levelList.indexWhere((x) => x.contains('hard'));
    int expertCutoffIndex = levelList.indexWhere((x) => x.contains('expert'));
    for (int i = 1; i < levelList.length + 1; i++) {
      // line
      if (i > 1) {
        barWidgets.add(
          Container(
            height: 1,
            width: 8,
            decoration: BoxDecoration(
              color: level >= i
                  ? Theme.of(context).highlightColor.withAlpha(230)
                  : Colors.grey,
            ),
          ),
        );
      }
      // dot
      Color ballColor = const Color(0xff07f5e1);
      if (i - 1 >= mediumCutoffIndex) {
        ballColor = Color(0xff42a3eb);
      }
      if (i - 1 >= hardCutoffIndex) {
        ballColor = Color(0xff7c52f5);
      }
      if (i - 1 >= expertCutoffIndex) {
        ballColor = Color(0xffb700ff);
      }
      if (data['beatFinalLevel']) {
        ballColor = Theme.of(context).canvasColor;
      }
      barWidgets.add(
        data['state'] == 'scoreboard' &&
                data['rules']['mode'] == 'Survival' &&
                level == i
            ? Icon(MdiIcons.skull, size: 22, color: gameColors[samesiesString])
            : Container(
                height: progressBallLength + (level == i ? 7 : 0),
                width: progressBallLength + (level == i ? 7 : 0),
                decoration: BoxDecoration(
                  color: i > level ? ballColor.withAlpha(50) : ballColor,
                  border: Border.all(
                    color:
                        i <= level ? Colors.black : Colors.white.withAlpha(0),
                  ),
                  borderRadius: BorderRadius.circular(progressBallLength + 20),
                ),
              ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: barWidgets,
    );
  }

  checkRoundOver(data) {
    // if all players are done, move to "comparison" page
    bool allPlayersSubmitted = true;
    int limit = getSubmissionLimit(data);
    data['playerIds'].forEach((v) {
      if (data['playerWords$v'].length < limit) {
        allPlayersSubmitted = false;
      }
    });
    // increment / check if game is over
    var timerExpired =
        data['expirationTime'].toDate().difference(_now).inSeconds < 0;
    if (allPlayersSubmitted || timerExpired) {
      // store team results
      data['teams'].asMap().forEach((i, v) {
        storeTeamResults(i, timerExpired, data);
      });
      if (data['rules']['mode'] == 'Survival') {
        if (!teamPasses(data)) {
          data['state'] = 'scoreboard';
        }
      }
      if (data['state'] != 'scoreboard') {
        incrementLevel(data);
      }
      // reset playerWords and ready states
      data['playerIds'].forEach((v) {
        data['playerWords$v'] = [];
        data['ready$v'] = false;
      });
      data['expirationTime'] = null;
    }

    T.transact(data);
    setState(() {
      _controller.text = '';
      isUpdating = false;
    });
    myFocusNode.requestFocus();
  }

  getStatus(data) {
    bool isRunning = data['expirationTime'] != null;
    if (isRunning) {
      var seconds = data['expirationTime'].toDate().difference(_now).inSeconds;
      // if seconds is negative, round must be ended
      if (seconds < 0 && !isUpdating) {
        checkRoundOver(data);
        isUpdating = true;
      }
    }
    String word = '';
    data['teams'].asMap().forEach((i, v) {
      if (data['teams'][i]['players'].contains(widget.userId)) {
        word = data['teams'][i]['words'][data['level']];
      }
    });
    var level = 'Level ${levelToNumber(data)}';
    String difficultyString =
        data['level'].substring(0, data['level'].length - 1).toUpperCase();
    String difficultyIndex =
        data['level'].substring(data['level'].length - 1).toUpperCase();
    var difficulty = '($difficultyString #${int.parse(difficultyIndex) + 1})';
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
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).highlightColor),
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).dialogBackgroundColor,
      ),
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                level,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 15),
              Text(
                difficulty,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          getLevelProgress(data),
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
        ? Column(
            children: [
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 5,
                  width: remainingPercentage * width,
                  decoration: BoxDecoration(
                    color: gameColors[samesiesString],
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
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
          color: data['playerWords${widget.userId}'].length > i
              ? gameColors[samesiesString]
              : Theme.of(context).highlightColor.withAlpha(5),
        ),
        height: 20,
        width: 20,
      ));
      submissionWidgets.add(SizedBox(width: 10));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: submissionWidgets,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  playerReady(data) async {
    data['ready${widget.userId}'] = true;

    data = await T.transactSamesiesReady(widget.userId);

    // if all players are ready, start the timer
    bool allReady = true;
    data['playerIds'].forEach((v) {
      if (!data['ready$v']) {
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
    var width = MediaQuery.of(context).size.width;
    List<Widget> player1Words = [
      Container(
        width: width * 0.32,
        height: 30,
        child: AutoSizeText(
          data['playerNames'][data['teams'][teamIndex]['players'][0]],
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
          ),
        ),
      ),
      PageBreak(width: 60),
      SizedBox(height: 5),
    ];
    List<Widget> player2Words = [
      Container(
        width: width * 0.32,
        height: 30,
        child: AutoSizeText(
          data['playerNames'][data['teams'][teamIndex]['players'][1]],
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
          ),
        ),
      ),
      PageBreak(width: 60),
      SizedBox(height: 5),
    ];

    int score = 0;
    data['teams'][teamIndex]['results'].forEach((v) {
      score += v['score'];
    });

    bool complete = false;
    if (data['state'] == 'scoreboard') {
      complete = true;
    }

    bool isWinner = false;
    int maxScore = 0;
    data['teams'].forEach((v) {
      if (v['score'] > maxScore) {
        maxScore = v['score'];
      }
    });
    if (data['teams'][teamIndex]['score'] == maxScore) {
      isWinner = true;
    }
    if (data['rules']['mode'] == 'Survival') {
      isWinner = false;
    }

    bool isLost = complete && !data['beatFinalLevel'];

    data['teams'][teamIndex]['results'].forEach((v) {
      player1Words.add(Container(
          height: 25,
          width: width * 0.3,
          child: Center(
            child: AutoSizeText(
              v['words'][0] == '' ? '-' : v['words'][0],
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
          width: width * 0.3,
          child: Center(
            child: AutoSizeText(
              v['words'][1] == '' ? '-' : v['words'][1],
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
    });
    return Column(
      children: [
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            complete && isWinner
                ? Icon(
                    isLost ? MdiIcons.skull : MdiIcons.crown,
                    color: isLost
                        ? Theme.of(context).highlightColor
                        : Colors.amber,
                    size: 40,
                  )
                : Container(),
            SizedBox(width: 10),
            Column(
              children: [
                Text('Team ${teamIndex + 1}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    )),
                SizedBox(height: 5),
                PageBreak(width: 50),
                Container(
                  width: width * 0.33,
                  child: AutoSizeText(
                      '${data['teams'][teamIndex]['words'][data['level'] == 'expert2' ? data['level'] : previousLevel(data)].toUpperCase()}',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                      )),
                ),
                SizedBox(height: 5),
                PageBreak(width: 50),
                Text('Round Score:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    )),
                Text('$score',
                    style: TextStyle(
                      fontSize: 20,
                    )),
              ],
            ),
            SizedBox(width: 5),
            complete
                ? Column(
                    children: [
                      Text(
                        'Total Score:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${data['teams'][teamIndex]['score']}',
                        style: TextStyle(
                          fontSize: 40,
                        ),
                      ),
                    ],
                  )
                : Container(),
            SizedBox(width: 10),
            complete && isWinner
                ? Icon(
                    isLost ? MdiIcons.skull : MdiIcons.crown,
                    color: isLost
                        ? Theme.of(context).highlightColor
                        : Colors.amber,
                    size: 40,
                  )
                : Container(),
          ],
        ),
        data['rules']['mode'] == 'Survival'
            ? Text(
                '(needed ${data['level'] == 'expert2' ? requiredScoreForLevel(data) : requiredScoreForLevel(data, previous: true)})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ))
            : Container(width: 0),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
              child: Column(children: player1Words),
            ),
            SizedBox(width: 15),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
              child: Column(
                children: player2Words,
              ),
            ),
          ],
        ),
      ],
    );
  }

  getRoundSummary(data) {
    bool complete = data['state'] == 'scoreboard';
    bool beatFinalLevel = data['beatFinalLevel'];
    List<Widget> teamResultWidgets = [
      Text(
          complete
              ? beatFinalLevel
                  ? 'Game complete!'
                  : 'You got knocked out on level ${levelToNumber(data)}'
              : 'Level ${levelToNumber(data) - 1} complete!',
          style: TextStyle(
            fontSize: 22,
            // color: gameColors[samesiesString],
          )),
      SizedBox(height: 10),
      complete
          ? Column(
              children: [
                getLevelProgress(data),
                SizedBox(height: 10),
              ],
            )
          : Container(),
    ];
    data['teams'].asMap().forEach((i, v) {
      teamResultWidgets.add(getTeamResults(i, data));
      teamResultWidgets.add(SizedBox(height: 20));
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
            data['ready$v']
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

    var width = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: width * 0.95,
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
              child: Text('Ready!', style: TextStyle(fontSize: 32)),
              gradient: LinearGradient(
                colors: !data['ready${widget.userId}']
                    ? [
                        gameColors[samesiesString],
                        gameColors[samesiesString].withAlpha(100),
                      ]
                    : [
                        Colors.grey,
                        Colors.grey,
                      ],
              ),
              onPressed: !data['ready${widget.userId}']
                  ? () {
                      playerReady(data);
                    }
                  : null,
            ),
            SizedBox(height: 10),
            data['rules']['mode'] == 'Survival'
                ? Column(
                    children: [
                      Text(
                        'Next round requires at least',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${requiredScoreForLevel(data)} out of ${getSubmissionLimit(data)} correct',
                        style: TextStyle(
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        'to pass',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '(Next round has ${getSubmissionLimit(data)} submission words)'),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  storeTeamResults(teamIndex, timerExpired, data) {
    var player1Id = data['teams'][teamIndex]['players'][0];
    var player2Id = data['teams'][teamIndex]['players'][1];
    List player1Words = List.of(data['playerWords$player1Id']);
    List player2Words = List.of(data['playerWords$player2Id']);
    // fill each list to capacity with null in case player ran out of time
    while (player1Words.length < getSubmissionLimit(data)) {
      player1Words.add('');
    }
    while (player2Words.length < getSubmissionLimit(data)) {
      player2Words.add('');
    }
    List unmatchedPlayer1Words = [];
    List matchedPlayer2Words = [];
    // iterate over one players score, check if it exists in the other one
    player1Words.forEach((player1Word) {
      bool matchFound = false;
      player2Words.forEach((player2Word) {
        if (player1Word != '' && player2Word != '') {
          if (StringSimilarity.compareTwoStrings(
                  player1Word.toLowerCase(), player2Word.toLowerCase()) >
              matchFactor) {
            data['teams'][teamIndex]['results'].add({
              'words': [player1Word, player2Word],
              'similarity':
                  StringSimilarity.compareTwoStrings(player1Word, player2Word),
              'score': 1
            });
            matchedPlayer2Words.add(player2Word);
            matchFound = true;
          }
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
        'words': [
          unmatchedPlayer1Words[i],
          player2Words[i],
        ],
        'similarity': StringSimilarity.compareTwoStrings(
            unmatchedPlayer1Words[i], player2Words[i]),
        'score': 0,
      });
    }

    int roundScore = 0;
    data['teams'][teamIndex]['results'].forEach((v) {
      roundScore += v['score'];
    });

    data['teams'][teamIndex]['score'] += roundScore;
  }

  teamPasses(data) {
    bool passes = true;
    int score = 0;
    data['teams'][0]['results'].forEach((result) {
      score += result['score'];
    });
    if (score >= requiredScoreForLevel(data)) {
    } else {
      passes = false;
    }

    if (passes) {
      return true;
    }
    return false;
  }

  submitWord(data) async {
    if (submittingWord || _controller.text == '') {
      return;
    }
    bool isBadWord = false;
    setState(() {
      submittingWord = true;
    });
    // check word isn't the clue word
    String word = '';
    data['teams'].asMap().forEach((i, v) {
      if (data['teams'][i]['players'].contains(widget.userId)) {
        word = data['teams'][i]['words'][data['level']];
      }
    });
    if (StringSimilarity.compareTwoStrings(_controller.text, word) >
        matchFactor) {
      Flushbar(
        flushbarPosition: FlushbarPosition.TOP,
        title: 'Can\'t submit clue word!',
        message: 'Bruh.',
        duration: Duration(seconds: 3),
      ).show(context);
      isBadWord = true;
    }

    // check word isn't already submitted
    data['playerWords${widget.userId}'].forEach((v) {
      if (StringSimilarity.compareTwoStrings(_controller.text, v) >
          matchFactor) {
        Flushbar(
          flushbarPosition: FlushbarPosition.TOP,
          title: 'Similar word already submitted!',
          message: 'Try another word.',
          duration: Duration(seconds: 3),
        ).show(context);
        isBadWord = true;
      }
    });
    if (isBadWord) {
      setState(() {
        _controller.text = '';
        submittingWord = false;
      });
      return;
    }

    HapticFeedback.vibrate();

    data['playerWords${widget.userId}'].add(_controller.text);

    data = await T.transactSamesiesWord(widget.userId, _controller.text);

    setState(() {
      submittingWord = false;
    });

    checkRoundOver(data);
  }

  getSubmit(data) {
    var width = MediaQuery.of(context).size.width;

    // if player is done, show awaiting
    int limit = getSubmissionLimit(data);
    if (data['playerWords${widget.userId}'].length >= limit) {
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
              Container(),
              Text(data['playerNames'][v]),
              SizedBox(width: 5),
              data['playerWords$v'].length >= limit
                  ? Icon(MdiIcons.checkBoxOutline, color: Colors.green)
                  : Icon(MdiIcons.checkboxBlank, color: Colors.grey),
              SizedBox(width: 5),
              Text(
                data['playerWords$v'].length >= limit
                    ? '              '
                    : '(${data['playerWords$v'].length}/$limit done)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
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

    String word = '';
    data['teams'].asMap().forEach((i, v) {
      if (data['teams'][i]['players'].contains(widget.userId)) {
        word = data['teams'][i]['words'][data['level']];
      }
    });
    int remainingSubmissions =
        limit - data['playerWords${widget.userId}'].length;

    // words submitted so far
    List<Widget> submittedWords = [];
    data['playerWords${widget.userId}'].forEach((v) {
      submittedWords.add(Text(
        v,
        style: TextStyle(color: Theme.of(context).highlightColor),
      ));
    });

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
              onSubmitted: submittingWord
                  ? null
                  : (s) {
                      submitWord(data);
                    },
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
                hintText: '${word.toUpperCase()} makes me think of...',
                hintStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
          SizedBox(height: 10),
          RaisedGradientButton(
            height: 40,
            width: 180,
            onPressed: () {
              submitWord(data);
            },
            child: Text(
              submittingWord ? 'Submitting...' : 'Submit (or hit enter)',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            gradient: LinearGradient(
                colors: submittingWord
                    ? [
                        Colors.grey,
                        Colors.grey,
                      ]
                    : [
                        Theme.of(context).primaryColor,
                        Theme.of(context).accentColor
                      ]),
          ),
          SizedBox(height: 10),
          Text('($remainingSubmissions remaining)',
              style: TextStyle(color: Colors.grey)),
          submittedWords.length > 0 ? SizedBox(height: 10) : Container(),
          submittedWords.length > 0
              ? Column(children: submittedWords)
              : Container(),
        ],
      ),
    );
  }

  getScoreboard(data) {
    return TogetherScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            getRoundSummary(data),
            widget.userId == data['leader']
                ? EndGameButton(
                    sessionId: widget.sessionId,
                    fontSize: 14,
                    height: 30,
                    width: 100,
                  )
                : Container(),
            SizedBox(height: 40),
          ],
        ),
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
