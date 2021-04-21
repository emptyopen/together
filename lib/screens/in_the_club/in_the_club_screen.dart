import 'dart:math';

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
  String submitAnswerError;
  String submitQuestionError;
  int minNumVotes = 5;

  @override
  void initState() {
    super.initState();
    T = Transactor(sessionId: widget.sessionId);
    var random = Random();
    randomIndex = random.nextInt(inTheClubSampleQuestions.length - 1);
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

  checkIfVibrate(data) {
    bool isNewVibrateData = false;

    if (isNewVibrateData) {
      HapticFeedback.vibrate();
    }
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
    finalQuestion = finalQuestion.trim();
    if (!finalQuestion.endsWith('?')) {
      finalQuestion += '?';
    }
    finalQuestion = finalQuestion.inCaps;

    // check that question doesn't already exist
    bool similarAnswerExists = false;
    data['playerIds'].asMap().forEach((i, playerId) {
      data['player${i}Questions'].forEach((otherQuestion) {
        if (StringSimilarity.compareTwoStrings(finalQuestion, otherQuestion) >
            0.7) {
          similarAnswerExists = true;
        }
      });
    });
    if (similarAnswerExists) {
      submitQuestionError = 'Someone has already submitted a similar question!';
      setState(() {});
      return;
    }
    submitQuestionError = null;
    setState(() {});

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
      await T.transact(data);
    }
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

    int questionsRemaining = data['rules']['numQuestionsPerPlayer'] -
        data['player${playerIndex}Questions'].length;

    return Column(
      children: [
        Text(
          'Compose a question!',
          style: TextStyle(
            fontSize: 22,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'The question should be subjective, and should have at least 4 answers.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'You can submit $questionsRemaining more question' +
              (questionsRemaining > 1 ? 's' : '') +
              '.',
        ),
        SizedBox(height: 5),
        TextField(
          controller: questionCollectionController,
          textInputAction: TextInputAction.send,
          onSubmitted: submittingWord
              ? null
              : (s) {
                  submitQuestion(data);
                },
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
        submitQuestionError != null
            ? Column(
                children: [
                  SizedBox(height: 5),
                  Text(
                    submitQuestionError,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Container(),
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

    // close keyboard
    closeKeyboardIfOpen(context);

    // clean input
    answer = answer.trim();

    // ensure similar answer doesn't already exist
    bool similarAnswerExists = false;
    data['playerIds'].asMap().forEach((i, playerId) {
      data['player${i}Answers'].forEach((otherAnswer) {
        if (StringSimilarity.compareTwoStrings(answer, otherAnswer) > 0.7) {
          similarAnswerExists = true;
        }
      });
    });
    if (similarAnswerExists) {
      submitAnswerError = 'Someone has already submitted a similar answer!';
      setState(() {});
      return;
    }
    submitAnswerError = null;
    setState(() {});

    var playerIndex = data['playerIds'].indexOf(widget.userId);
    // submit
    data = await T.transactInTheClubAnswer(playerIndex, answer);
    setState(() {
      answerCollectionController.text = '';
    });
    // check if all players are done, if so set phase to answerCollection
    bool allPlayersDone = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (data['player${i}Votes'].length < minNumVotes) {
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
      await T.transact(data);
    }
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
    setState(() {});

    // check if all players are done voting
    bool allPlayersDoneVoting = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!data['player${i}DoneVoting']) {
        allPlayersDoneVoting = false;
      }
    });

    if (allPlayersDoneVoting) {
      // get four best answers, "random" if tie
      // init with map of all answers
      Map totalMapping = {};
      data['playerIds'].asMap().forEach((i, playerId) {
        data['player${i}Answers'].forEach((answer) {
          totalMapping[answer] = 0;
        });
      });
      data['playerIds'].asMap().forEach((i, playerId) {
        data['player${i}Votes'].forEach((word, votes) {
          totalMapping[word] += votes;
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
      });
      // save answers
      // TODO: randomize here
      data['finalAnswers'][data['finalAnswers'].length.toString()] =
          bestAnswers;
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
        // initialize club membership to first question group
        data['clubMembership'] = {};
        data['finalAnswers']['0'].forEach((answer) {
          data['clubMembership'][answer] = [];
        });
      }
      data = await T.transact(data);
    }
    setState(() {});
  }

  answerCollectionBoard(data) {
    var width = MediaQuery.of(context).size.width;
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    int currentPlayer = (data['answerCollectionQuestionIndex'] ~/
        data['rules']['numQuestionsPerPlayer']);
    String currentQuestion = data['player${currentPlayer}Questions'][
        data['answerCollectionQuestionIndex'] %
            data['rules']['numQuestionsPerPlayer']];

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
          onTap: data['player${playerIndex}DoneVoting'] || numAnswers < 4
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
                colors: !data['player${playerIndex}Answers'].contains(answer)
                    ? [
                        Colors.lightBlue[400].withAlpha(200),
                        Colors.lightBlue[200].withAlpha(200),
                      ]
                    : [
                        Colors.purple[400].withAlpha(200),
                        Colors.purple[200].withAlpha(200),
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
                        color: Colors.black,
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
                    'Enter your answers here!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'You can submit up to ${maxAnswers - numSubmitted} more answer' +
                        (maxAnswers - numSubmitted > 1 ? 's' : '') +
                        '.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: answerCollectionController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: submittingWord
                        ? null
                        : (s) {
                            submitAnswer(data);
                          },
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
                  submitAnswerError != null
                      ? Column(
                          children: [
                            SizedBox(height: 5),
                            Text(
                              submitAnswerError,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Container(),
                  SizedBox(height: 20),
                ],
              ),
        Column(
          children: [
            Text(
              'Answers from everybody will show up below.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            Text(
              'Tap answers to vote! Your answers are purple.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'You can vote as many times as you like, but if you vote on your own answer more than anyone else did, you won\'t get points for it!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 5),
            numAnswers < 4
                ? Text(
                    'We need at least 4 answers before voting can begin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(),
                  )
                : Container(),
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
            data['player${playerIndex}DoneVoting']
                ? Container()
                : Column(
                    children: [
                      SizedBox(height: 10),
                      numVotes < minNumVotes
                          ? Text(
                              'You need to vote at least ${minNumVotes - numVotes} more times!')
                          : Container(),
                      SizedBox(height: 10),
                      RaisedGradientButton(
                        height: 30,
                        width: 120,
                        onPressed: numVotes < minNumVotes
                            ? () {}
                            : () {
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
                            colors: submittingWord || numVotes < minNumVotes
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
        ),
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

  playerJoinedClub(data, playerId) {
    bool playerJoinedClub = false;
    data['clubMembership'].forEach((answer, members) {
      if (members.contains(playerId)) {
        playerJoinedClub = true;
      }
    });
    return playerJoinedClub;
  }

  submitClubSelection(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    String selectedAnswer = data['finalAnswers']
        [data['clubSelectionQuestionIndex'].toString()][selectedTileIndex];
    data['clubMembership'][selectedAnswer].add(widget.userId);
    data['player${playerIndex}ClubSelected'] = true;
    data = await T.transact(data);
    setState(() {});

    // check if all players have submitted club selection, if so add points
    bool allPlayersJoinedClub = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!playerJoinedClub(data, playerId)) {
        allPlayersJoinedClub = false;
      }
    });
    if (allPlayersJoinedClub) {
      int maxClubMembers = 0;
      data['clubMembership'].forEach((answer, members) {
        if (members.length > maxClubMembers) {
          maxClubMembers = members.length;
        }
      });
      data['clubMembership'].forEach((answer, members) {
        if (members.length == maxClubMembers) {
          members.forEach((member) {
            int memberIndex = data['playerIds'].indexOf(member);
            data['player${memberIndex}Points'] += members.length + 1;
          });
        } else {
          members.forEach((member) {
            int memberIndex = data['playerIds'].indexOf(member);
            data['player${memberIndex}Points'] += members.length;
          });
        }
      });
    }
    data = await T.transact(data);
  }

  playerReady(data) async {
    HapticFeedback.vibrate();
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Ready'] = true;
    data = await T.transact(data);

    // check if all players are ready
    bool allPlayersReady = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!data['player${i}Ready']) {
        allPlayersReady = false;
      }
    });
    int numQuestions = data['finalAnswers'].length;
    if (allPlayersReady) {
      if (data['clubSelectionQuestionIndex'] < numQuestions - 1) {
        data['clubSelectionQuestionIndex'] += 1;
        // reset values
        selectedTileIndex = null;
        data['playerIds'].asMap().forEach((i, playerId) {
          data['player${i}Ready'] = false;
        });
        data['clubMembership'] = {};
        data['finalAnswers'][data['clubSelectionQuestionIndex'].toString()]
            .forEach((answer) {
          data['clubMembership'][answer] = [];
        });
      } else {
        if (data['rules']['numWouldYouRather'] > 0) {
          data['phase'] = 'wouldYouRather';
          data['wouldYouRatherQuestionIndex'] = 0;
          // initialize club membership
          selectedTileIndex = null;
          data['playerIds'].asMap().forEach((i, playerId) {
            data['player${i}Ready'] = false;
          });
          data['clubMembership'] = {};
          data['wouldYouRatherQuestions']['0'].forEach((answer) {
            data['clubMembership'][answer] = [];
          });
        } else {
          data['phase'] = 'scoreboard';
        }
      }
      data = await T.transact(data);
    }
  }

  clubSelectionBoard(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    int currentPlayer = (data['clubSelectionQuestionIndex'] ~/
        data['rules']['numQuestionsPerPlayer']);
    String currentQuestion = data['player${currentPlayer}Questions'][
        data['clubSelectionQuestionIndex'] %
            data['rules']['numQuestionsPerPlayer']];

    List<Widget> playerStatuses = [];
    data['playerIds'].asMap().forEach((i, playerId) {
      playerStatuses.add(AutoSizeText(
        '${data['playerNames'][playerId]}:  ' +
            (playerJoinedClub(data, playerId)
                ? 'joined a club'
                : 'looking at clubs'),
        maxLines: 1,
        style: TextStyle(
          fontSize: 16,
          decoration: !playerJoinedClub(data, playerId)
              ? TextDecoration.none
              : TextDecoration.lineThrough,
          color: !playerJoinedClub(data, playerId)
              ? Theme.of(context).highlightColor
              : Colors.grey,
        ),
      ));
    });

    // check if all players have selected a club
    // if not, move to next question or, if done, to roundSummary
    bool allPlayersJoinedClub = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!playerJoinedClub(data, playerId)) {
        allPlayersJoinedClub = false;
      }
    });

    int maxClubMembers = 0;
    data['clubMembership'].forEach((answer, members) {
      if (members.length > maxClubMembers) {
        maxClubMembers = members.length;
      }
    });

    List<Widget> playerReadyStatuses = [];
    data['playerIds'].asMap().forEach((i, v) {
      playerReadyStatuses.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data['playerNames'][v]),
            SizedBox(width: 5),
            data['player${i}Ready']
                ? Icon(MdiIcons.checkBoxOutline, color: Colors.green)
                : Icon(MdiIcons.checkboxBlank, color: Colors.grey),
          ],
        ),
      );
    });

    return Column(
      children: [
        Text(
          currentQuestion,
          style: TextStyle(fontSize: 26),
        ),
        SizedBox(height: 10),
        allPlayersJoinedClub
            ? Container()
            : Column(
                children: [
                  Text(
                    'Choose your club below!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubSelectionTile(
                  data: data,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 0;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership'][data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][0]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][data['finalAnswers'][
                              data['clubSelectionQuestionIndex'].toString()][0]]
                          .length,
                  answer: data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][0],
                  selected: selectedTileIndex == 0,
                ),
                SizedBox(height: 10),
                ClubSelectionTile(
                  data: data,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 1;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership'][data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][1]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][data['finalAnswers'][
                              data['clubSelectionQuestionIndex'].toString()][1]]
                          .length,
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
                  data: data,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 2;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership'][data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][2]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][data['finalAnswers'][
                              data['clubSelectionQuestionIndex'].toString()][2]]
                          .length,
                  answer: data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][2],
                  selected: selectedTileIndex == 2,
                ),
                SizedBox(height: 10),
                ClubSelectionTile(
                  data: data,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 3;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership'][data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][3]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][data['finalAnswers'][
                              data['clubSelectionQuestionIndex'].toString()][3]]
                          .length,
                  answer: data['finalAnswers']
                      [data['clubSelectionQuestionIndex'].toString()][3],
                  selected: selectedTileIndex == 3,
                ),
              ],
            ),
          ],
        ),
        allPlayersJoinedClub
            ? Column(
                children: [
                  SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Theme.of(context).highlightColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Text(data['clubSelectionQuestionIndex'] !=
                                data['playerIds'].length *
                                        data['rules']['numQuestionsPerPlayer'] -
                                    1
                            ? 'Ready for next question:'
                            : data['rules']['numWouldYouRather'] == 0
                                ? 'Ready for scoreboard:'
                                : 'Ready for "would you rather":'),
                        SizedBox(height: 5),
                        PageBreak(width: 100),
                        Column(children: playerReadyStatuses),
                        SizedBox(height: 10),
                        RaisedGradientButton(
                          height: 30,
                          width: 110,
                          onPressed: () {
                            playerReady(data);
                          },
                          child: Text(
                            'Ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          gradient: LinearGradient(
                            colors: data['player${playerIndex}Ready']
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
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              )
            : playerJoinedClub(data, widget.userId)
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
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(height: 10),
                      RaisedGradientButton(
                        height: 40,
                        width: 120,
                        onPressed: selectedTileIndex == null
                            ? () {}
                            : () {
                                submitClubSelection(data);
                              },
                        child: Text(
                          submittingWord ? 'Submitting...' : 'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: selectedTileIndex == null || submittingWord
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
                  ),
      ],
    );
  }

  submitClubSelectionWouldYouRather(data) async {
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    String selectedAnswer = data['wouldYouRatherQuestions']
        [data['wouldYouRatherQuestionIndex'].toString()][selectedTileIndex];
    data['clubMembership'][selectedAnswer].add(widget.userId);
    data['player${playerIndex}ClubSelected'] = true;
    // data = await T.transact(data);

    // check if all players have submitted club selection, if so add points
    bool allPlayersJoinedClub = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!playerJoinedClub(data, playerId)) {
        allPlayersJoinedClub = false;
      }
    });
    if (allPlayersJoinedClub) {
      int maxClubMembers = 0;
      data['clubMembership'].forEach((answer, members) {
        if (members.length > maxClubMembers) {
          maxClubMembers = members.length;
        }
      });
      data['clubMembership'].forEach((answer, members) {
        if (members.length == maxClubMembers) {
          members.forEach((member) {
            int memberIndex = data['playerIds'].indexOf(member);
            data['player${memberIndex}Points'] += (members.length + 1) * 2;
          });
        } else {
          members.forEach((member) {
            int memberIndex = data['playerIds'].indexOf(member);
            data['player${memberIndex}Points'] += members.length * 2;
          });
        }
      });
    }
    data = await T.transact(data);
  }

  playerReadyWouldYouRather(data) async {
    HapticFeedback.vibrate();
    var playerIndex = data['playerIds'].indexOf(widget.userId);
    data['player${playerIndex}Ready'] = true;
    data = await T.transact(data);

    // check if all players are ready
    bool allPlayersReady = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!data['player${i}Ready']) {
        allPlayersReady = false;
      }
    });
    if (allPlayersReady) {
      if (data['wouldYouRatherQuestionIndex'] <
          data['rules']['numWouldYouRather'] - 1) {
        data['wouldYouRatherQuestionIndex'] += 1;
        // reset values
        selectedTileIndex = null;
        data['playerIds'].asMap().forEach((i, playerId) {
          data['player${i}Ready'] = false;
        });
        data['clubMembership'] = {};
        data['wouldYouRatherQuestions']
                [data['wouldYouRatherQuestionIndex'].toString()]
            .forEach((answer) {
          data['clubMembership'][answer] = [];
        });
      } else {
        data['phase'] = 'scoreboard';
      }
      data = await T.transact(data);
    }
  }

  wouldYouRatherBoard(data) {
    var playerIndex = data['playerIds'].indexOf(widget.userId);

    List<Widget> playerStatuses = [];
    data['playerIds'].asMap().forEach((i, playerId) {
      playerStatuses.add(AutoSizeText(
        '${data['playerNames'][playerId]}:  ' +
            (playerJoinedClub(data, playerId)
                ? 'joined a club'
                : 'looking at clubs'),
        maxLines: 1,
        style: TextStyle(
          fontSize: 16,
          decoration: !playerJoinedClub(data, playerId)
              ? TextDecoration.none
              : TextDecoration.lineThrough,
          color: !playerJoinedClub(data, playerId)
              ? Theme.of(context).highlightColor
              : Colors.grey,
        ),
      ));
    });

    // check if all players have selected a club
    // if not, move to next question or, if done, to roundSummary
    bool allPlayersJoinedClub = true;
    data['playerIds'].asMap().forEach((i, playerId) {
      if (!playerJoinedClub(data, playerId)) {
        allPlayersJoinedClub = false;
      }
    });

    int maxClubMembers = 0;
    data['clubMembership'].forEach((answer, members) {
      if (members.length > maxClubMembers) {
        maxClubMembers = members.length;
      }
    });

    List<Widget> playerReadyStatuses = [];
    data['playerIds'].asMap().forEach((i, v) {
      playerReadyStatuses.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data['playerNames'][v]),
            SizedBox(width: 5),
            data['player${i}Ready']
                ? Icon(MdiIcons.checkBoxOutline, color: Colors.green)
                : Icon(MdiIcons.checkboxBlank, color: Colors.grey),
          ],
        ),
      );
    });

    var wouldYouRatherRoundQuestions = data['wouldYouRatherQuestions']
        [data['wouldYouRatherQuestionIndex'].toString()];

    return Column(
      children: [
        Text(
          'Would You Rather:',
          style: TextStyle(fontSize: 26),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubSelectionTile(
                  data: data,
                  isWouldYouRather: true,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 0;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership']
                      [wouldYouRatherRoundQuestions[0]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][wouldYouRatherRoundQuestions[0]]
                          .length,
                  answer: wouldYouRatherRoundQuestions[0],
                  selected: selectedTileIndex == 0,
                ),
                SizedBox(height: 10),
                ClubSelectionTile(
                  data: data,
                  isWouldYouRather: true,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 1;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership']
                      [wouldYouRatherRoundQuestions[1]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][wouldYouRatherRoundQuestions[1]]
                          .length,
                  answer: wouldYouRatherRoundQuestions[1],
                  selected: selectedTileIndex == 1,
                ),
              ],
            ),
            SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClubSelectionTile(
                  data: data,
                  isWouldYouRather: true,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 2;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership']
                      [wouldYouRatherRoundQuestions[2]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][wouldYouRatherRoundQuestions[2]]
                          .length,
                  answer: wouldYouRatherRoundQuestions[2],
                  selected: selectedTileIndex == 2,
                ),
                SizedBox(height: 10),
                ClubSelectionTile(
                  data: data,
                  isWouldYouRather: true,
                  callback: playerJoinedClub(data, widget.userId)
                      ? () {}
                      : () {
                          HapticFeedback.vibrate();
                          selectedTileIndex = 3;
                          setState(() {});
                        },
                  showMembers: allPlayersJoinedClub,
                  members: data['clubMembership']
                      [wouldYouRatherRoundQuestions[3]],
                  isTheClub: maxClubMembers ==
                      data['clubMembership'][wouldYouRatherRoundQuestions[3]]
                          .length,
                  answer: wouldYouRatherRoundQuestions[3],
                  selected: selectedTileIndex == 3,
                ),
              ],
            ),
          ],
        ),
        allPlayersJoinedClub
            ? Column(
                children: [
                  SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Theme.of(context).highlightColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Text(data['wouldYouRatherQuestionIndex'] !=
                                data['rules']['numWouldYouRather'] - 1
                            ? 'Ready for next question:'
                            : 'Ready for scoreboard:'),
                        SizedBox(height: 5),
                        PageBreak(width: 100),
                        Column(children: playerReadyStatuses),
                        SizedBox(height: 10),
                        RaisedGradientButton(
                          height: 30,
                          width: 110,
                          onPressed: () {
                            playerReadyWouldYouRather(data);
                          },
                          child: Text(
                            'Ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          gradient: LinearGradient(
                            colors: data['player${playerIndex}Ready']
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
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              )
            : playerJoinedClub(data, widget.userId)
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
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(height: 10),
                      RaisedGradientButton(
                        height: 40,
                        width: 120,
                        onPressed: selectedTileIndex == null
                            ? () {}
                            : () {
                                submitClubSelectionWouldYouRather(data);
                              },
                        child: Text(
                          submittingWord ? 'Submitting...' : 'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: selectedTileIndex == null || submittingWord
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
                  ),
      ],
    );
  }

  scoreboard(data) {
    List<Widget> scores = [];
    int highestScore = 0;
    List<String> bestPlayers = [];
    data['playerIds'].asMap().forEach((i, playerId) {
      scores.add(
        Text(
          '${data['playerNames'][playerId]}: ${data['player${i}Points']} pts',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
      if (data['player${i}Points'] > highestScore) {
        highestScore = data['player${i}Points'];
        bestPlayers = [data['playerNames'][playerId]];
      } else if (data['player${i}Points'] == highestScore) {
        bestPlayers.add(data['playerNames'][playerId]);
      }
    });
    var width = MediaQuery.of(context).size.width;
    List<Widget> winnerNames = [];
    bestPlayers.forEach((name) {
      winnerNames.add(
        Container(
          width: width * 0.6,
          child: AutoSizeText(
            name,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
            ),
          ),
        ),
      );
    });

    return Column(
      children: [
        Text(
          'Thanks for playing!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 15),
        Text(
          bestPlayers.length == 1
              ? 'The club master is:'
              : 'The club masters are:',
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(
              MdiIcons.emoticonCoolOutline,
              size: 34,
            ),
            Icon(
              MdiIcons.emoticonCoolOutline,
              size: 34,
            ),
          ],
        ),
        SizedBox(height: 20),
        Column(children: winnerNames),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(
              MdiIcons.emoticonCoolOutline,
              size: 34,
            ),
            Icon(
              MdiIcons.emoticonCoolOutline,
              size: 34,
            ),
          ],
        ),
        SizedBox(height: 25),
        Text(
          'The final scores were:',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 10),
        Column(children: scores),
      ],
    );
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
      case 'scoreboard':
        return 'Scoreboard';
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
    } else if (data['phase'] == 'wouldYouRather') {
      board = wouldYouRatherBoard(data);
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
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
          SizedBox(height: 20),
          Container(
            width: width * 0.9,
            decoration: basicBoxDecoration(
                color: data['phase'] == 'scoreboard' ? null : null),
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

  basicBoxDecoration({color}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: Theme.of(context).highlightColor,
      ),
      color: color == null ? Theme.of(context).dialogBackgroundColor : color,
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
        checkIfVibrate(data);
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
