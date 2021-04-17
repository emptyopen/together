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

import 'in_the_club_components.dart';
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
  int selectedTileIndex;

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

    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // submit
    data = await T.transactInTheClubQuestion(playerIndex, finalQuestion);
    setState(() {
      questionCollectionController.text = '';
    });
    // check if all players are done, if so set phase to answerCollection
    bool allPlayersDone = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (data['player${i}Questions'].length <
          data['rules']['numQuestionsPerPlayer']) {
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
                  ],
          ),
        ),
        data['player${playerIndex}Questions'].length > 0
            ? SizedBox(height: 15)
            : Container(),
        data['player${playerIndex}Questions'].length > 0
            ? Text(
                'Already submitted:',
                style: TextStyle(
                  color: Colors.grey,
                ),
              )
            : Container(),
        data['player${playerIndex}Questions'].length > 0
            ? SizedBox(height: 5)
            : Container(),
        Column(children: submittedQuestions),
      ],
    );
  }

  submitAnswer(data) async {
    HapticFeedback.vibrate();
    String answer = answerCollectionController.text;

    // ensure similar answer doesn't already exist

    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // submit
    data = await T.transactInTheClubAnswer(playerIndex, answer);
    setState(() {
      answerCollectionController.text = '';
    });
    // check if all players are done, if so set phase to answerCollection
    bool allPlayersDone = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (data['player${i}Votes'].length < 10) {
        allPlayersDone = false;
      }
    });
    // ensure there are at least 4 answers
    List<Widget> possibleAnswers = [];
    data['playerIds'].asMap().forEach((i, playerId) {
      data['player${i}Answers'].forEach((answer) {
        possibleAnswers.add(Text(answer));
      });
    });
    if (possibleAnswers.length < 4) {
      allPlayersDone = false;
    }
    if (allPlayersDone) {
      data['phase'] = 'answerCollection';
      data['answerCollectionQuestionIndex'] = 0;
    }
    await T.transact(data);
  }

  getVoteCountForWord(data, word) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    return '${data['player${playerIndex}Votes'][word] ?? 0}';
  }

  submitVote(data, word) async {
    HapticFeedback.vibrate();
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data = await T.transactInTheClubVote(playerIndex, word);
    setState(() {});
  }

  doneVoting(data) async {
    HapticFeedback.vibrate();
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}DoneVoting'] = true;
    data = await T.transact(data);

    // check if all players are done voting
    bool allPlayersDoneVoting = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!data['player${i}DoneVoting']) {
        allPlayersDoneVoting = false;
      }
    });

    if (allPlayersDoneVoting) {
      // get four best answers, "random" if tie
      Map totalMapping = {};
      data['playerIds'].asMap().forEach((i, playerId) {
        data['player${i}Votes'].forEach((word, votes) {
          if (totalMapping.containsKey(word)) {
            totalMapping[word] += votes;
          } else {
            totalMapping[word] = votes;
          }
        });
      });
      var bestAnswers = totalMapping.keys.toList(growable: false)
        ..sort((k1, k2) => totalMapping[k2].compareTo(totalMapping[k1]));
      // add points for each player who came up with answers (if applicable)
      bestAnswers = bestAnswers.sublist(0, 4);
      bestAnswers.forEach((word) {
        int playerIndexForWord = 0;
        data['playerIds'].asMap().forEach((i, playerId) {
          if (data['player${i}Answers'].contains(word)) {
            playerIndexForWord = i;
          }
        });
        // determine player index for highest bidder for answer
        int highestVoterForWord = 0;
        int maxVotes = 0;
        data['playerIds'].asMap().forEach((i, playerId) {
          if ((data['player${i}Votes'][word] ?? 0) > maxVotes) {
            highestVoterForWord = i;
            maxVotes = data['player${i}Votes'][word];
          }
        });
        if (playerIndexForWord != highestVoterForWord) {
          data['player${playerIndexForWord}Points'] += 2;
        }
        // save answers
        data['clubMembership'] = {};
        bestAnswers.forEach((bestAnswer) {
          data['clubMembership'][bestAnswer] = [];
        });
        data['finalAnswers'][data['finalAnswers'].length().toString()] =
            bestAnswers;
      });
      // next question, or move to answer submission
      if (data['answerCollectionQuestionIndex'] <
          data['playerIds'].length * data['rules']['numQuestionsPerPlayer'] -
              1) {
        // next question
        data['answerCollectionQuestionIndex'] += 1;
        // reset answers, votes, doneVoting
        data['playerIds'].asMap().forEach((i, playerId) {
          data['player${i}Answers'] = [];
          data['player${i}Votes'] = {};
          data['player${i}DoneVoting'] = false;
        });
      } else {
        data['phase'] = 'clubSelection';
      }
      data = await T.transact(data);
    }
    setState(() {});
  }

  answerCollectionBoard(data) {
    var width = MediaQuery.of(context).size.width;
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    int currentPlayer = (data['answerCollectionQuestionIndex'] ~/ 2);
    String currentQuestion = data['player${currentPlayer}Questions']
        [data['answerCollectionQuestionIndex'] % 2];

    // possible answers. for each player, append all answers
    // to do: use shared seed to randomize order of players?
    List<String> possibleAnswers = [];
    data['playerIds'].asMap().forEach((i, playerId) {
      data['player${i}Answers'].forEach((answer) {
        possibleAnswers.add(answer);
      });
    });

    List<Widget> possibleAnswerColumns = [];
    List<Widget> possibleAnswerColumn = [SizedBox(height: 5)];
    possibleAnswers.forEach((answer) {
      possibleAnswerColumn.add(
        GestureDetector(
          onTap: data['player${playerIndex}DoneVoting']
              ? () {}
              : () {
                  submitVote(data, answer);
                },
          child: Container(
            height: 33,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                colors: [
                  Colors.lightBlue[400].withAlpha(200),
                  Colors.lightBlue[200].withAlpha(200),
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                SizedBox(width: 5),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).highlightColor),
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white.withAlpha(200),
                  ),
                  padding: EdgeInsets.all(2),
                  height: 20,
                  width: 20,
                  child: Center(
                    child: AutoSizeText(
                      getVoteCountForWord(data, answer),
                      maxLines: 1,
                      minFontSize: 5,
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      possibleAnswerColumn.add(SizedBox(height: 5));
      if (possibleAnswerColumn.length > 10) {
        possibleAnswerColumns.add(Column(children: possibleAnswerColumn));
        possibleAnswerColumns.add(SizedBox(width: 5));
        possibleAnswerColumn = [SizedBox(height: 5)];
      }
    });
    if (possibleAnswerColumn.length > 1) {
      possibleAnswerColumns.add(Column(children: possibleAnswerColumn));
    }

    int maxAnswers = data['rules']['numAnswersPerPlayer'];
    int numSubmitted = data['player${playerIndex}Answers'].length;

    List<Widget> playerStatuses = [];
    data['playerIds'].asMap().forEach((i, playerId) {
      int playerVotes = 0;
      data['player${i}Votes'].forEach((word, votes) {
        playerVotes += votes;
      });
      bool playerDoneVoting = data['player${i}DoneVoting'];
      playerStatuses.add(AutoSizeText(
        '${data['playerNames'][playerId]}:  $playerVotes votes',
        maxLines: 1,
        style: TextStyle(
          fontSize: 16,
          decoration: !playerDoneVoting
              ? TextDecoration.none
              : TextDecoration.lineThrough,
          color: !playerDoneVoting
              ? Theme.of(context).highlightColor
              : Colors.grey,
        ),
      ));
    });

    int numAnswers = 0;
    data['playerIds'].asMap().forEach((i, playerId) {
      data['player${i}Answers'].forEach((answer) {
        numAnswers += 1;
      });
    });

    int numVotes = 0;
    data['player${playerIndex}Votes'].forEach((word, votes) {
      numVotes += votes;
    });

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
        numSubmitted >= maxAnswers
            ? Container()
            : Column(
                children: [
                  Text(
                    'Enter suggestions here! (${maxAnswers - numSubmitted} submission' +
                        (maxAnswers - numSubmitted == 0 ? 's' : '') +
                        ' available)',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: answerCollectionController,
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
                      submittingWord
                          ? 'Submitting...'
                          : 'Submit (or hit enter)',
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
                ],
              ),
        numAnswers >= 4
            ? Column(
                children: [
                  Text(
                    'Vote here! (Need at least 10 votes)',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    height: 200,
                    width: width * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: possibleAnswerColumns,
                    ),
                  ),
                  numVotes < 10 || data['player${playerIndex}DoneVoting']
                      ? Container()
                      : Column(
                          children: [
                            SizedBox(height: 10),
                            RaisedGradientButton(
                              height: 30,
                              width: 120,
                              onPressed: () {
                                doneVoting(data);
                              },
                              child: Text(
                                'Done voting',
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
                          ],
                        ),
                ],
              )
            : Text('Waiting on at least 4 answers...'),
        data['player${playerIndex}DoneVoting']
            ? Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Who to heckle:',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  PageBreak(width: 110),
                  Column(children: playerStatuses),
                  SizedBox(height: 30),
                  data['answerCollectionQuestionIndex'] !=
                          data['playerIds'].length *
                                  data['rules']['numQuestionsPerPlayer'] -
                              1
                      ? Container()
                      : Text(
                          '(next up is club selection!)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                ],
              )
            : Container(),
      ],
    );
  }

  submitClubSelection(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    String selectedAnswer = data['selectedAnswers'][selectedTileIndex];
    data['clubMembership'][selectedAnswer].add(widget.userId);
    data['player${playerIndex}ClubSelected'] = true;
    data = await T.transact(data);

    // check if all players have selected a club
    // if so, move to next question or, if done, to roundSummary
    setState(() {});
  }

  clubSelectionBoard(data) {
    int currentPlayer = (data['answerCollectionQuestionIndex'] ~/ 2);
    String currentQuestion = data['player${currentPlayer}Questions']
        [data['answerCollectionQuestionIndex'] % 2];
    return Column(
      children: [
        Text(
          currentQuestion,
          style: TextStyle(fontSize: 26),
        ),
        SizedBox(height: 10),
        Text(
          'Choose your club below!',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubSelectionTile(
                  callback: () {
                    HapticFeedback.vibrate();
                    selectedTileIndex = 0;
                    setState(() {});
                  },
                  answer: data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][0],
                  selected: selectedTileIndex == 0,
                ),
                SizedBox(height: 10),
                ClubSelectionTile(
                  callback: () {
                    HapticFeedback.vibrate();
                    selectedTileIndex = 1;
                    setState(() {});
                  },
                  answer: data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][1],
                  selected: selectedTileIndex == 1,
                ),
              ],
            ),
            SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubSelectionTile(
                  callback: () {
                    HapticFeedback.vibrate();
                    selectedTileIndex = 2;
                    setState(() {});
                  },
                  answer: data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][2],
                  selected: selectedTileIndex == 2,
                ),
                SizedBox(height: 10),
                ClubSelectionTile(
                  callback: () {
                    HapticFeedback.vibrate();
                    selectedTileIndex = 3;
                    setState(() {});
                  },
                  answer: data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][3],
                  selected: selectedTileIndex == 3,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        RaisedGradientButton(
          height: 40,
          width: 180,
          onPressed: () {
            submitClubSelection(data);
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
                  ],
          ),
        ),
      ],
    );
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
      case 'clubSelection':
        return 'Club Selection';
        break;
      case 'wouldYouRather':
        return 'Would You Rather';
        break;
    }
    return 'error';
  }

  getGameboard(data) {
    var width = MediaQuery.of(context).size.width;
    Widget board = scoreboard(data);
    if (data['phase'] == 'questionCollection') {
      board = questionCollectionBoard(data);
    } else if (data['phase'] == 'answerCollection') {
      board = answerCollectionBoard(data);
    } else if (data['phase'] == 'clubSelection') {
      board = clubSelectionBoard(data);
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
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Column(
                  children: [
                    Text(
                      'Phase:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 5),
                    Text(
                      phaseInEnglish(data),
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
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
