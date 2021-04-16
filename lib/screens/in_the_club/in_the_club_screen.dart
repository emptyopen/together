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

import 'in_the_club_services.dart';

class InTheClubScreen extends StatefulWidget {
  InTheClubScreen({this.sessionId, this.userId, this.roomCode});

  final String sessionId;
  final String userId;
  final String roomCode;

  @override
  _InTheClubScreenState createState() => _InTheClubScreenState();
}

class _InTheClubScreenState extends State<InTheClubScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isSpectator = false;
  var T;
  TextEditingController questionCollectionController =
      new TextEditingController();
  TextEditingController answerCollectionController =
      new TextEditingController();
  bool submittingWord = false;
  int randomIndex = 0;

  @override
  void initState() {
    super.initState();
    T = Transactor(sessionId: widget.sessionId);
    setUpGame();
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

  playerReady(data) async {
    data['ready${widget.userId}'] = true;

    data = await T.transactInTheClubReady(widget.userId);

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

  getScoreboard(data) {
    return TogetherScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Text('scoreboard'),
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

  submitQuestion(data) async {
    HapticFeedback.vibrate();
    String finalQuestion = questionCollectionController.text;

    // clean input
    if (!finalQuestion.endsWith('?')) {
      finalQuestion += '?';
    }
    finalQuestion = finalQuestion.inCaps;

    print('yo');

    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // submit
    data = await T.transactInTheClubQuestion(playerIndex, finalQuestion);
    setState(() {
      questionCollectionController.text = '';
    });
    // check if all players are done, if so set phase to answerCollection
    bool allPlayersDone = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      print(i);
      if (data['player${i}Questions'].length <
          data['rules']['numQuestionsPerPlayer']) {
        print('what');
        allPlayersDone = false;
      }
    });
    if (allPlayersDone) {
      data['phase'] = 'answerCollection';
      data['answerCollectionQuestionIndex'] = 0;
    }
    await T.transact(data);
  }

  questionCollectionBoard(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);

    List<Widget> submittedQuestions = [];
    data['player${playerIndex}Questions'].forEach((playerQuestion) {
      submittedQuestions.add(Text(playerQuestion));
    });

    List<Widget> playerStatuses = [];
    data['playerIds'].asMap().forEach((i, playerId) {
      int playerSubmissions = data['player${i}Questions'].length;
      int maxSubmissions = data['rules']['numQuestionsPerPlayer'];
      playerStatuses.add(AutoSizeText(
        '${data['playerNames'][playerId]}:  $playerSubmissions/$maxSubmissions',
        maxLines: 1,
        style: TextStyle(
          fontSize: 20,
          decoration: playerSubmissions < maxSubmissions
              ? TextDecoration.none
              : TextDecoration.lineThrough,
          color: playerSubmissions < maxSubmissions
              ? Theme.of(context).highlightColor
              : Colors.grey,
        ),
      ));
    });

    if (data['player${playerIndex}Questions'].length >=
        data['rules']['numQuestionsPerPlayer']) {
      return Column(
        children: [
          Text(
            'You\'re all done!',
            style: TextStyle(
              fontSize: 28,
            ),
          ),
          PageBreak(width: 170),
          SizedBox(height: 20),
          Text(
            'You submitted:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 10),
          Column(children: submittedQuestions),
          SizedBox(height: 30),
          Text(
            'Who to heckle:',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          PageBreak(width: 110),
          Column(children: playerStatuses),
          SizedBox(height: 30),
          Text(
            '(next up is answer collection!)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Give us a question:',
          style: TextStyle(
            fontSize: 22,
          ),
        ),
        Text(
          '${data['player${playerIndex}Questions'].length}/${data['rules']['numQuestionsPerPlayer']} submitted',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: questionCollectionController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            border: OutlineInputBorder(),
            helperText: 'ex: "${inTheClubSampleQuestions[randomIndex]}"',
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        RaisedGradientButton(
          height: 40,
          width: 180,
          onPressed: () {
            submitQuestion(data);
          },
          child: Text(
            submittingWord ? 'Submitting...' : 'Submit (or hit enter)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
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
        SizedBox(height: 15),
        Text(
          'Already submitted:',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 5),
        Column(children: submittedQuestions),
      ],
    );
  }

  submitAnswer(data) async {
    HapticFeedback.vibrate();
    String finalQuestion = answerCollectionController.text;

    // clean input
    if (!finalQuestion.endsWith('?')) {
      finalQuestion += '?';
    }
    finalQuestion = finalQuestion.inCaps;

    print('yo');

    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // submit
    data = await T.transactInTheClubQuestion(playerIndex, finalQuestion);
    setState(() {
      questionCollectionController.text = '';
    });
    // check if all players are done, if so set phase to answerCollection
    bool allPlayersDone = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      print(i);
      if (data['player${i}Questions'].length <
          data['rules']['numQuestionsPerPlayer']) {
        print('what');
        allPlayersDone = false;
      }
    });
    if (allPlayersDone) {
      data['phase'] = 'answerCollection';
      data['answerCollectionQuestionIndex'] = 0;
    }
    await T.transact(data);
  }

  answerCollectionBoard(data) {
    var width = MediaQuery.of(context).size.width;
    int currentPlayer = (data['answerCollectionQuestionIndex'] ~/ 2);
    String currentQuestion = data['player${currentPlayer}Questions']
        [data['answerCollectionQuestionIndex'] % 2];
    return Column(
      children: [
        Text(
          'Answer this question:',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 10),
        AutoSizeText(
          '$currentQuestion',
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Enter suggestion here!',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: questionCollectionController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            border: OutlineInputBorder(),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        RaisedGradientButton(
          height: 30,
          width: 150,
          onPressed: () {
            submitAnswer(data);
          },
          child: Text(
            submittingWord ? 'Submitting...' : 'Submit (or hit enter)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
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
        SizedBox(height: 20),
        Text(
          'Vote here!',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 5),
        Container(
          height: 200,
          width: width * 0.9,
          decoration: basicBoxDecoration(),
        ),
      ],
    );
  }

  answerSubmissionBoard(data) {
    return Text('Answer Submission');
  }

  roundSummaryBoard(data) {
    return Text('Round Summary');
  }

  wouldYouRatherBoard(data) {
    return Text('Would You Rather');
  }

  scoreboard(data) {
    return Text('Scoreboard');
  }

  phaseInEnglish(data) {
    switch (data['phase']) {
      case 'questionCollection':
        return 'Question Collection';
        break;
      case 'answerCollection':
        return 'Answer Collection';
        break;
      case 'answerSubmission':
        return 'Answer Submission';
        break;
      case 'wouldYouRather':
        return 'Would You Rather';
        break;
    }
  }

  getGameboard(data) {
    var width = MediaQuery.of(context).size.width;
    Widget board = scoreboard(data);
    if (data['phase'] == 'questionCollection') {
      board = questionCollectionBoard(data);
    } else if (data['phase'] == 'answerCollection') {
      board = answerCollectionBoard(data);
    } else if (data['phase'] == 'answerSubmission') {
      board = answerSubmissionBoard(data);
    } else if (data['phase'] == 'roundSummary') {
      board = roundSummaryBoard(data);
    } else if (data['phase'] == 'wouldYouRather') {
      board = wouldYouRatherBoard(data);
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: basicBoxDecoration(),
                padding: EdgeInsets.all(10),
                child: Text(
                  phaseInEnglish(data),
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(width: 20),
              roomCode(data),
            ],
          ),
          // internal board
          SizedBox(height: 30),
          Container(
            width: width * 0.9,
            decoration: basicBoxDecoration(),
            padding: EdgeInsets.all(20),
            child: board,
          ),
          // end button
          SizedBox(height: 30),
          widget.userId == data['leader']
              ? EndGameButton(
                  sessionId: widget.sessionId,
                  fontSize: 14,
                  height: 30,
                  width: 100,
                )
              : Container(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  basicBoxDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: Theme.of(context).highlightColor,
      ),
      color: Theme.of(context).dialogBackgroundColor,
    );
  }

  roomCode(data) {
    return Container(
        decoration: basicBoxDecoration(),
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
                'In The Club',
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
                'In The Club',
              ),
            ),
            body: Container(),
          );
        }
        checkIfExit(data, context, widget.sessionId, widget.roomCode);
        return Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                'In The Club',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) {
                          return InTheClubScreenHelp();
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
